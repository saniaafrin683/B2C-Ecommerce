package com.styleora.service;

import com.styleora.dao.ProductDao;
import java.util.List;
import java.util.Locale;
import java.util.Objects;
import java.util.concurrent.ThreadLocalRandom;

import com.styleora.dao.WarehouseDao;
import com.styleora.model.Product;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.util.StringUtils;
import org.springframework.web.server.ResponseStatusException;

import com.styleora.dao.ReceivedOrderDao;
import com.styleora.model.ReceivedOrder;
import com.styleora.model.Warehouse;

import jakarta.transaction.Transactional;

@Service
public class ReceivedOrderService {

    @Autowired
    private ReceivedOrderDao receivedOrderDao;

    @Autowired
    private ProductDao productDao;

    @Autowired
    private WarehouseDao warehouseDao;

    @Transactional
    public ReceivedOrder saveReceivedOrder(ReceivedOrder order) {
        if (order == null) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Received order payload is required.");
        }

        normalizeAndValidate(order, true);
        Product product = requireProduct(order.getProductId());
        Warehouse warehouse = requireWarehouse(order.getWarehouseId());
        populateLookupFields(order, product, warehouse);
        order.setStockApplied(false);

        if (!StringUtils.hasText(order.getOrderNo())) {
            order.setOrderNo(generateOrderNo());
        }

        ReceivedOrder savedOrder = receivedOrderDao.saveReceivedOrder(order);
        applyStockIfEligible(savedOrder);
        return savedOrder;
    }

    public List<ReceivedOrder> getAllReceivedOrders() {
        return receivedOrderDao.getAllReceivedOrders();
    }

    public ReceivedOrder getReceivedOrderById(Long id) {
        ReceivedOrder receivedOrder = receivedOrderDao.getReceivedOrderById(id);
        if (receivedOrder == null) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "Received order not found.");
        }
        return receivedOrder;
    }

    @Transactional
    public ReceivedOrder updateReceivedOrder(Long id, ReceivedOrder order) {
        if (order == null) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Received order payload is required.");
        }

        ReceivedOrder existingOrder = getReceivedOrderForUpdate(id);
        validateCompletedOrderEdit(existingOrder, order);
        normalizeAndValidate(order, false);

        Product product = requireProduct(order.getProductId());
        Warehouse warehouse = requireWarehouse(order.getWarehouseId());

        existingOrder.setOrderNo(order.getOrderNo());
        existingOrder.setSupplierName(order.getSupplierName());
        existingOrder.setWarehouseId(order.getWarehouseId());
        existingOrder.setWarehouseName(warehouse.getWarehouseName());
        existingOrder.setProductId(order.getProductId());
        existingOrder.setProductName(product.getName());
        existingOrder.setQuantity(order.getQuantity());
        existingOrder.setReceivedDate(order.getReceivedDate());
        existingOrder.setStatus(normalizeStatus(order.getStatus()));
        existingOrder.setTotalAmount(normalizeAmount(order.getTotalAmount()));

        ReceivedOrder updatedOrder = receivedOrderDao.updateReceivedOrder(existingOrder);
        applyStockIfEligible(updatedOrder);
        return updatedOrder;
    }

    @Transactional
    public ReceivedOrder updateStatus(Long id, String requestedStatus) {
        ReceivedOrder existingOrder = getReceivedOrderForUpdate(id);
        String normalizedStatus = normalizeStatus(requestedStatus);
        String currentStatus = normalizeStatus(existingOrder.getStatus());

        if (isCompleted(currentStatus) && !isCompleted(normalizedStatus)) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST,
                    "Completed received orders cannot be moved back to pending."
            );
        }

        existingOrder.setStatus(normalizedStatus);
        ReceivedOrder updatedOrder = receivedOrderDao.updateReceivedOrder(existingOrder);
        applyStockIfEligible(updatedOrder);
        return updatedOrder;
    }

    public void deleteReceivedOrder(Long id) {
        ReceivedOrder existingOrder = receivedOrderDao.getReceivedOrderById(id);
        if (existingOrder == null) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "Received order not found.");
        }
        if (Boolean.TRUE.equals(existingOrder.getStockApplied())) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST,
                    "Completed received orders cannot be deleted because stock has already been applied."
            );
        }
        receivedOrderDao.deleteReceivedOrder(id);
    }

    private ReceivedOrder getReceivedOrderForUpdate(Long id) {
        ReceivedOrder receivedOrder = receivedOrderDao.getReceivedOrderByIdForUpdate(id);
        if (receivedOrder == null) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "Received order not found.");
        }
        return receivedOrder;
    }

    private void applyStockIfEligible(ReceivedOrder order) {
        if (!isCompleted(order.getStatus()) || Boolean.TRUE.equals(order.getStockApplied())) {
            return;
        }

        Product product = requireProduct(order.getProductId());
        Warehouse warehouse = requireWarehouse(order.getWarehouseId());

        boolean productUpdated = productDao.increaseStock(product.getId(), normalizeQuantity(order.getQuantity()));
        if (!productUpdated) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Unable to increase product stock.");
        }

        boolean warehouseUpdated = warehouseDao.increaseStockAvailable(warehouse.getId(), normalizeQuantity(order.getQuantity()));
        if (!warehouseUpdated) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Unable to increase warehouse stock.");
        }

        order.setStockApplied(true);
        receivedOrderDao.updateReceivedOrder(order);
    }

    private void normalizeAndValidate(ReceivedOrder order, boolean creating) {
        order.setOrderNo(trimToNull(order.getOrderNo()));
        order.setSupplierName(requireText(order.getSupplierName(), "Supplier name is required."));
        order.setWarehouseName(trimToNull(order.getWarehouseName()));
        order.setProductName(trimToNull(order.getProductName()));
        order.setWarehouseId(requireId(order.getWarehouseId(), "Warehouse is required."));
        order.setProductId(requireId(order.getProductId(), "Product is required."));
        order.setQuantity(normalizeQuantity(order.getQuantity()));
        order.setStatus(normalizeStatus(order.getStatus()));
        order.setTotalAmount(normalizeAmount(order.getTotalAmount()));

        if (order.getReceivedDate() == null) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Received date is required.");
        }

        if (!creating && !StringUtils.hasText(order.getOrderNo())) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Order number is required.");
        }
    }

    private void validateCompletedOrderEdit(ReceivedOrder existingOrder, ReceivedOrder requestedOrder) {
        if (!Boolean.TRUE.equals(existingOrder.getStockApplied())) {
            return;
        }

        if (!Objects.equals(existingOrder.getProductId(), requestedOrder.getProductId())
                || !Objects.equals(existingOrder.getWarehouseId(), requestedOrder.getWarehouseId())
                || normalizeQuantity(existingOrder.getQuantity()) != normalizeQuantity(requestedOrder.getQuantity())) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST,
                    "Completed received orders cannot change product, warehouse, or quantity after stock is applied."
            );
        }
    }

    private Product requireProduct(Long productId) {
        Product product = productDao.getProductById(productId);
        if (product == null) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "Selected product not found.");
        }
        return product;
    }

    private Warehouse requireWarehouse(Long warehouseId) {
        Warehouse warehouse = warehouseDao.getWarehouseById(warehouseId);
        if (warehouse == null) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "Selected warehouse not found.");
        }
        return warehouse;
    }

    private void populateLookupFields(ReceivedOrder order, Product product, Warehouse warehouse) {
        order.setProductId(product.getId());
        order.setProductName(product.getName());
        order.setWarehouseId(warehouse.getId());
        order.setWarehouseName(warehouse.getWarehouseName());
    }

    private String normalizeStatus(String status) {
        if (!StringUtils.hasText(status)) {
            return "Pending";
        }

        String normalized = status.trim().toLowerCase(Locale.ROOT);
        if ("completed".equals(normalized)) {
            return "Completed";
        }
        if ("pending".equals(normalized)) {
            return "Pending";
        }

        throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Status must be Pending or Completed.");
    }

    private boolean isCompleted(String status) {
        return "completed".equalsIgnoreCase(status);
    }

    private int normalizeQuantity(Integer quantity) {
        int normalized = quantity == null ? 0 : quantity;
        if (normalized <= 0) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Quantity must be at least 1.");
        }
        return normalized;
    }

    private double normalizeAmount(Double totalAmount) {
        double normalized = totalAmount == null ? 0D : totalAmount;
        if (normalized < 0D) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Total amount cannot be negative.");
        }
        return normalized;
    }

    private Long requireId(Long id, String message) {
        if (id == null || id <= 0L) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, message);
        }
        return id;
    }

    private String requireText(String value, String message) {
        String normalized = trimToNull(value);
        if (!StringUtils.hasText(normalized)) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, message);
        }
        return normalized;
    }

    private String trimToNull(String value) {
        return StringUtils.hasText(value) ? value.trim() : null;
    }

    private String generateOrderNo() {
        return "RO-" + System.currentTimeMillis() + "-" + ThreadLocalRandom.current().nextInt(100, 1000);
    }
}
