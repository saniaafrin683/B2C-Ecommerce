package com.styleora.service;

import com.styleora.dto.CouponApplicationResult;
import com.styleora.dao.CustomerDao;
import com.styleora.dao.InvoiceDao;
import com.styleora.dao.OrderDao;
import com.styleora.dao.OrderItemDao;
import com.styleora.dao.PaymentDao;
import com.styleora.dao.ProductDao;
import com.styleora.dao.ReturnRequestDao;
import com.styleora.dao.ReviewDao;
import com.styleora.dao.ShipmentDao;
import com.styleora.dto.OrderDetailsResponse;
import com.styleora.dto.OrderItemPayload;
import com.styleora.dto.OrderRequest;
import com.styleora.dto.OrderStatusUpdateRequest;
import com.styleora.dto.OrderStatusUpdateResponse;
import com.styleora.model.Customer;
import com.styleora.model.Order;
import com.styleora.model.OrderItem;
import com.styleora.model.Product;
import com.styleora.model.Shipment;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.web.server.ResponseStatusException;
import jakarta.transaction.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

@Service
public class OrderService {

    private static final String DEFAULT_ORDER_STATUS = "Pending";
    private static final Map<String, String> ORDER_STATUS_ALIASES = createOrderStatusAliases();
    private static final Logger LOGGER = LoggerFactory.getLogger(OrderService.class);

    private final OrderDao orderDao;
    private final OrderItemDao orderItemDao;
    private final ProductDao productDao;
    private final CustomerDao customerDao;
    private final CouponService couponService;
    private final ShipmentDao shipmentDao;
    private final ReturnRequestDao returnRequestDao;
    private final ReviewDao reviewDao;
    private final InvoiceService invoiceService;
    private final PaymentService paymentService;
    private final InvoiceDao invoiceDao;
    private final PaymentDao paymentDao;
    private final OrderStatusSideEffectService orderStatusSideEffectService;

    public OrderService(OrderDao orderDao, OrderItemDao orderItemDao, ProductDao productDao, CustomerDao customerDao, CouponService couponService, ShipmentDao shipmentDao, ReturnRequestDao returnRequestDao, ReviewDao reviewDao, InvoiceService invoiceService, PaymentService paymentService, InvoiceDao invoiceDao, PaymentDao paymentDao, OrderStatusSideEffectService orderStatusSideEffectService) {
        this.orderDao = orderDao;
        this.orderItemDao = orderItemDao;
        this.productDao = productDao;
        this.customerDao = customerDao;
        this.couponService = couponService;
        this.shipmentDao = shipmentDao;
        this.returnRequestDao = returnRequestDao;
        this.reviewDao = reviewDao;
        this.invoiceService = invoiceService;
        this.paymentService = paymentService;
        this.invoiceDao = invoiceDao;
        this.paymentDao = paymentDao;
        this.orderStatusSideEffectService = orderStatusSideEffectService;
    }

    @Transactional
    public OrderDetailsResponse createOrder(OrderRequest request) {
        List<OrderItemPayload> requestedItems = request.getOrderItems();
        if (requestedItems == null || requestedItems.isEmpty()) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "At least one order item is required.");
        }

        Customer customer = null;
        if (request.getCustomerEmail() != null && !request.getCustomerEmail().trim().isEmpty()) {
            customer = customerDao.findByEmail(request.getCustomerEmail().trim());
        }

        ValidatedOrder validatedItems = validateAndPrepareItems(requestedItems);
        ValidatedOrder validatedOrder = buildValidatedOrder(validatedItems.items(), request);
        LOGGER.info(
                "Creating guest/admin order: orderId={}, couponCode={}, couponDiscount={}, subtotalAfterProductDiscount={}, finalTotal={}",
                request.getOrderId(),
                validatedOrder.couponCode(),
                validatedOrder.couponDiscount(),
                validatedOrder.subtotalAfterProductDiscount(),
                validatedOrder.finalTotal()
        );
        Order order = mapToOrder(request, customer, validatedOrder);
        Order savedOrder = orderDao.saveOrder(order);
        LOGGER.info(
                "Saved order id={}, orderId={}, couponCode={}, couponDiscount={}, totalAmount={}",
                savedOrder.getId(),
                savedOrder.getOrderId(),
                savedOrder.getCouponCode(),
                savedOrder.getCouponDiscount(),
                savedOrder.getTotalAmount()
        );
        saveOrderItems(savedOrder, validatedOrder.items());
        createInvoiceAndPaymentForOrder(savedOrder);
        consumeCouponIfApplied(validatedOrder);

        if (customer != null) {
            customer.setTotalOrders((customer.getTotalOrders() == null ? 0 : customer.getTotalOrders()) + 1);
            customer.setTotalSpend((customer.getTotalSpend() == null ? 0D : customer.getTotalSpend()) + validatedOrder.finalTotal());
        }

        return getOrderById(savedOrder.getId());
    }

    @Transactional
    public OrderDetailsResponse createOrderForCustomer(String customerEmail, OrderRequest request) {
        Customer customer = customerDao.findByEmail(customerEmail);
        if (customer == null) {
            throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Customer account not found.");
        }

        List<OrderItemPayload> requestedItems = request.getOrderItems();
        if (requestedItems == null || requestedItems.isEmpty()) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "At least one order item is required.");
        }

        ValidatedOrder validatedItems = validateAndPrepareItems(requestedItems);
        ValidatedOrder validatedOrder = buildValidatedOrder(validatedItems.items(), request);
        LOGGER.info(
                "Creating customer order: customerEmail={}, orderId={}, receivedCouponCode={}, validatedCouponCode={}, couponDiscount={}, subtotalAfterProductDiscount={}, finalTotal={}",
                customerEmail,
                request.getOrderId(),
                request.getCouponCode(),
                validatedOrder.couponCode(),
                validatedOrder.couponDiscount(),
                validatedOrder.subtotalAfterProductDiscount(),
                validatedOrder.finalTotal()
        );
        Order order = mapToOrder(request, customer, validatedOrder);
        Order savedOrder = orderDao.saveOrder(order);
        LOGGER.info(
                "Saved customer order id={}, orderId={}, customerEmail={}, couponCode={}, couponDiscount={}, totalAmount={}",
                savedOrder.getId(),
                savedOrder.getOrderId(),
                savedOrder.getCustomerEmail(),
                savedOrder.getCouponCode(),
                savedOrder.getCouponDiscount(),
                savedOrder.getTotalAmount()
        );
        saveOrderItems(savedOrder, validatedOrder.items());
        createInvoiceAndPaymentForOrder(savedOrder);
        consumeCouponIfApplied(validatedOrder);
        customer.setTotalOrders((customer.getTotalOrders() == null ? 0 : customer.getTotalOrders()) + 1);
        customer.setTotalSpend((customer.getTotalSpend() == null ? 0D : customer.getTotalSpend()) + validatedOrder.finalTotal());
        return getOrderById(savedOrder.getId());
    }

    public List<Order> getAllOrders() {
        List<Order> orders = orderDao.getAllOrders();
        LOGGER.info("Admin order list loaded count={}", orders.size());
        return orders;
    }

    public OrderDetailsResponse getOrderById(Long id) {
        Order order = orderDao.getOrderById(id);
        if (order == null) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "Order not found");
        }

        List<OrderItem> orderItems = orderItemDao.getOrderItemsByOrderId(id);
        return mapToDetailsResponse(order, orderItems);
    }

    public List<OrderDetailsResponse> getOrdersByCustomerEmail(String customerEmail) {
        List<Order> orders = orderDao.getOrdersByCustomerEmail(customerEmail);
        List<OrderDetailsResponse> responses = new ArrayList<>();

        for (Order order : orders) {
            responses.add(mapToDetailsResponse(order, new ArrayList<>()));
        }

        return responses;
    }

    public OrderDetailsResponse getCustomerOrderById(Long id, String customerEmail) {
        Order order = orderDao.getOrderByIdAndCustomerEmail(id, customerEmail);
        if (order == null) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "Order not found");
        }

        List<OrderItem> orderItems = orderItemDao.getOrderItemsByOrderId(id);
        return mapToDetailsResponse(order, orderItems);
    }

    public OrderDetailsResponse getCustomerOrderByOrderId(String orderId, String customerEmail) {
        if (orderId == null || orderId.trim().isEmpty()) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Order reference is required.");
        }

        Order order = orderDao.getOrderByOrderIdAndCustomerEmail(orderId.trim(), customerEmail);
        if (order == null) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "Order not found");
        }

        List<OrderItem> orderItems = orderItemDao.getOrderItemsByOrderId(order.getId());
        return mapToDetailsResponse(order, orderItems);
    }

    @Transactional
    public OrderDetailsResponse updateOrder(Long id, OrderRequest request) {
        Order existingOrder = orderDao.getOrderById(id);
        if (existingOrder == null) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "Order not found");
        }

        List<OrderItemPayload> existingItems = mapExistingItems(orderItemDao.getOrderItemsByOrderId(id));
        restoreStock(existingItems);

        ValidatedOrder validatedItems = validateAndPrepareItems(request.getOrderItems());
        ValidatedOrder validatedOrder = buildValidatedOrder(validatedItems.items(), request);
        Order order = mapToOrder(request, existingOrder.getCustomer(), validatedOrder);
        order.setId(id);
        Order updatedOrder = orderDao.updateOrder(order);
        if (order.getId() != null) {
            orderItemDao.deleteOrderItemsByOrderId(order.getId());
            saveOrderItems(updatedOrder, validatedOrder.items());
        }
        orderStatusSideEffectService.syncPaymentSnapshotsForStatusChange(
                updatedOrder.getId(),
                updatedOrder.getPaymentMethod(),
                updatedOrder.getOrderStatus()
        );
        return getOrderById(updatedOrder.getId());
    }

    @Transactional
    public OrderStatusUpdateResponse updateOrderStatus(Long id, OrderStatusUpdateRequest request) {
        Order existingOrder = orderDao.getOrderById(id);
        if (existingOrder == null) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "Order not found");
        }

        String normalizedStatus = normalizeOrderStatus(request != null ? request.getStatus() : null);
        Order updatedOrder = orderDao.updateOrderStatus(id, normalizedStatus);
        if (updatedOrder == null) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "Order not found");
        }

        String synchronizedPaymentStatus = resolvePaymentStatusForSnapshot(
                updatedOrder.getPaymentMethod(),
                normalizedStatus
        );
        if (synchronizedPaymentStatus != null) {
            updatedOrder.setPaymentStatus(synchronizedPaymentStatus);
        }

        LOGGER.info(
                "Order status updated id={}, orderId={}, previousStatus={}, newStatus={}",
                updatedOrder.getId(),
                updatedOrder.getOrderId(),
                existingOrder.getOrderStatus(),
                normalizedStatus
        );

        Order persistedOrder = orderDao.getOrderById(id);
        if (persistedOrder == null || !normalizedStatus.equals(persistedOrder.getOrderStatus())) {
            throw new ResponseStatusException(HttpStatus.CONFLICT, "Order status update was not persisted.");
        }

        try {
            orderStatusSideEffectService.syncPaymentSnapshotsForStatusChange(
                    persistedOrder.getId(),
                    persistedOrder.getPaymentMethod(),
                    persistedOrder.getOrderStatus()
            );
            persistedOrder = orderDao.getOrderById(id);
        } catch (Exception ex) {
            LOGGER.warn(
                    "Order status persisted but related payment snapshot sync failed for orderId={} (dbId={})",
                    persistedOrder.getOrderId(),
                    persistedOrder.getId(),
                    ex
            );
        }

        return new OrderStatusUpdateResponse(
                persistedOrder.getId(),
                persistedOrder.getOrderId(),
                persistedOrder.getOrderStatus(),
                persistedOrder.getPaymentStatus()
        );
    }

    @Transactional
    public void deleteOrder(Long id) {
        Order existingOrder = orderDao.getOrderById(id);
        if (existingOrder == null) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "Order not found");
        }

        restoreStock(mapExistingItems(orderItemDao.getOrderItemsByOrderId(id)));
        try {
            int deletedShipments = shipmentDao.deleteShipmentsByOrderId(id);
            int deletedReturnRequests = returnRequestDao.deleteReturnRequestsByOrderId(id);
            int deletedReviews = reviewDao.deleteReviewsByOrderId(id);
            int deletedPayments = paymentDao.deletePaymentsByOrderId(id);
            int deletedInvoices = invoiceDao.deleteInvoicesByOrderId(id);
            orderItemDao.deleteOrderItemsByOrderId(id);
            orderDao.clearPersistenceContext();
            orderDao.deleteOrder(id);
            LOGGER.info(
                    "Order deleted id={}, orderId={}, deletedShipments={}, deletedReturnRequests={}, deletedReviews={}, deletedPayments={}, deletedInvoices={}",
                    id,
                    existingOrder.getOrderId(),
                    deletedShipments,
                    deletedReturnRequests,
                    deletedReviews,
                    deletedPayments,
                    deletedInvoices
            );
        } catch (DataIntegrityViolationException ex) {
            throw new ResponseStatusException(
                    HttpStatus.CONFLICT,
                    "Order delete is blocked because other business records still reference this order.",
                    ex
            );
        } catch (Exception ex) {
            throw new ResponseStatusException(
                    HttpStatus.CONFLICT,
                    "Order delete failed because related records could not be removed safely.",
                    ex
            );
        }
    }

    private void saveOrderItems(Order order, List<OrderItemPayload> items) {
        if (order == null || order.getId() == null || items == null || items.isEmpty()) {
            return;
        }

        for (OrderItemPayload itemPayload : items) {
            OrderItem orderItem = new OrderItem();
            orderItem.setOrder(order);
            Product product = productDao.getProductById(itemPayload.getProductId());
            orderItem.setProduct(product);
            orderItem.setProductName(itemPayload.getProductName());
            orderItem.setProductImage(itemPayload.getProductImage());
            orderItem.setSize(itemPayload.getSize());
            orderItem.setColor(itemPayload.getColor());
            orderItem.setOriginalUnitPrice(itemPayload.getOriginalUnitPrice());
            orderItem.setDiscountedUnitPrice(itemPayload.getDiscountedUnitPrice());
            orderItem.setProductDiscountRate(itemPayload.getProductDiscountRate());
            orderItem.setProductDiscountAmount(itemPayload.getProductDiscountAmount());
            orderItem.setOriginalLineTotal(itemPayload.getOriginalLineTotal());
            orderItem.setProductDiscountLineTotal(itemPayload.getProductDiscountLineTotal());
            orderItem.setUnitPrice(itemPayload.getUnitPrice());
            orderItem.setQuantity(itemPayload.getQuantity());
            orderItem.setLineTotal(itemPayload.getLineTotal());
            orderItemDao.saveOrderItem(orderItem);
        }
    }

    private Order mapToOrder(OrderRequest request, Customer customer, ValidatedOrder validatedOrder) {
        Order order = new Order();
        order.setId(request.getId());
        order.setOrderId(request.getOrderId());
        order.setCreatedAt(request.getCreatedAt());
        order.setCustomer(customer);
        order.setCustomerName(customer != null ? customer.getFullName() : request.getCustomerName());
        order.setCustomerEmail(customer != null ? customer.getEmail() : request.getCustomerEmail());
        order.setCustomerPhone(normalizeString(request.getCustomerPhone(), customer != null ? customer.getPhone() : null));
        order.setShippingAddress(request.getShippingAddress());
        order.setBillingAddress(request.getBillingAddress());
        order.setPriority(request.getPriority());
        order.setSubtotal(validatedOrder.subtotalAfterProductDiscount());
        order.setRegularSubtotal(validatedOrder.regularSubtotal());
        order.setProductDiscountTotal(validatedOrder.productDiscountTotal());
        order.setSubtotalAfterProductDiscount(validatedOrder.subtotalAfterProductDiscount());
        order.setTax(validatedOrder.tax());
        order.setDiscount(validatedOrder.couponDiscount());
        order.setCouponDiscount(validatedOrder.couponDiscount());
        order.setShippingCost(validatedOrder.shippingCost());
        order.setCouponCode(validatedOrder.couponCode());
        order.setTotalAmount(validatedOrder.finalTotal());
        order.setPaymentMethod(request.getPaymentMethod());
        order.setDeliveryNumber(request.getDeliveryNumber());
        order.setTrackingNumber(request.getTrackingNumber());
        String normalizedOrderStatus = normalizeOrderStatus(request.getOrderStatus());
        order.setOrderStatus(normalizedOrderStatus);
        order.setPaymentStatus(resolvePaymentStatusForSnapshot(order.getPaymentMethod(), normalizedOrderStatus));
        return order;
    }

    private OrderDetailsResponse mapToDetailsResponse(Order order, List<OrderItem> orderItems) {
        OrderDetailsResponse response = new OrderDetailsResponse();
        response.setId(order.getId());
        response.setOrderId(order.getOrderId());
        response.setCreatedAt(order.getCreatedAt());
        response.setCustomerName(order.getCustomerName());
        response.setCustomerEmail(order.getCustomerEmail());
        response.setCustomerPhone(order.getCustomerPhone());
        response.setShippingAddress(order.getShippingAddress());
        response.setBillingAddress(order.getBillingAddress());
        response.setPriority(order.getPriority());
        response.setSubtotal(normalizeAmount(order.getSubtotal()));
        response.setRegularSubtotal(normalizeAmount(order.getRegularSubtotal()));
        response.setProductDiscountTotal(normalizeAmount(order.getProductDiscountTotal()));
        response.setSubtotalAfterProductDiscount(normalizeAmount(order.getSubtotalAfterProductDiscount()));
        response.setTax(normalizeAmount(order.getTax()));
        response.setDiscount(normalizeAmount(order.getDiscount()));
        response.setCouponDiscount(normalizeAmount(order.getCouponDiscount()));
        response.setShippingCost(normalizeAmount(order.getShippingCost()));
        response.setCouponCode(order.getCouponCode());
        response.setTotalAmount(normalizeAmount(order.getTotalAmount()));
        response.setPaymentMethod(order.getPaymentMethod());
        response.setPaymentStatus(order.getPaymentStatus());
        response.setDeliveryNumber(order.getDeliveryNumber());
        Shipment shipment = resolveLatestShipment(order.getId());
        response.setTrackingNumber(resolveTrackingNumber(order, shipment));
        response.setCourierName(shipment != null ? shipment.getCourierName() : null);
        response.setShipmentStatus(shipment != null ? shipment.getShipmentStatus() : null);
        response.setShippedDate(shipment != null ? shipment.getShippedDate() : null);
        response.setEstimatedDeliveryDate(shipment != null ? shipment.getEstimatedDeliveryDate() : null);
        response.setDeliveredDate(shipment != null ? shipment.getDeliveredDate() : null);
        response.setOrderStatus(order.getOrderStatus());

        List<OrderItemPayload> itemPayloads = new ArrayList<>();
        for (OrderItem orderItem : orderItems) {
            OrderItemPayload itemPayload = new OrderItemPayload();
            itemPayload.setId(orderItem.getId());
            itemPayload.setProductId(orderItem.getProduct() != null ? orderItem.getProduct().getId() : orderItem.getProductId());
            itemPayload.setProductName(orderItem.getProductName());
            itemPayload.setProductImage(orderItem.getProductImage());
            itemPayload.setSize(orderItem.getSize());
            itemPayload.setColor(orderItem.getColor());
            itemPayload.setOriginalUnitPrice(orderItem.getOriginalUnitPrice());
            itemPayload.setDiscountedUnitPrice(orderItem.getDiscountedUnitPrice());
            itemPayload.setProductDiscountRate(orderItem.getProductDiscountRate());
            itemPayload.setProductDiscountAmount(orderItem.getProductDiscountAmount());
            itemPayload.setOriginalLineTotal(orderItem.getOriginalLineTotal());
            itemPayload.setProductDiscountLineTotal(orderItem.getProductDiscountLineTotal());
            itemPayload.setUnitPrice(orderItem.getUnitPrice());
            itemPayload.setQuantity(orderItem.getQuantity());
            itemPayload.setLineTotal(orderItem.getLineTotal());
            itemPayloads.add(itemPayload);
        }

        response.setOrderItems(itemPayloads);
        return response;
    }

    private Shipment resolveLatestShipment(Long orderId) {
        if (orderId == null) {
            return null;
        }

        return shipmentDao.getLatestShipmentByOrderId(orderId);
    }

    private String resolveTrackingNumber(Order order, Shipment shipment) {
        if (shipment != null && shipment.getTrackingNumber() != null && !shipment.getTrackingNumber().trim().isEmpty()) {
            return shipment.getTrackingNumber().trim();
        }

        return order.getTrackingNumber();
    }

    private ValidatedOrder validateAndPrepareItems(List<OrderItemPayload> items) {
        List<OrderItemPayload> validatedItems = new ArrayList<>();
        BigDecimal regularSubtotal = BigDecimal.ZERO;
        BigDecimal subtotalAfterProductDiscount = BigDecimal.ZERO;

        for (OrderItemPayload itemPayload : items) {
            if (itemPayload.getProductId() == null) {
                throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Each order item must include a product id.");
            }

            int requestedQuantity = itemPayload.getQuantity() == null ? 0 : itemPayload.getQuantity();
            if (requestedQuantity <= 0) {
                throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Order item quantity must be at least 1.");
            }

            int reservedQuantity = itemPayload.getReservedQuantity() == null ? 0 : itemPayload.getReservedQuantity();
            if (reservedQuantity < 0 || reservedQuantity > requestedQuantity) {
                throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Reserved quantity is invalid for product " + itemPayload.getProductId() + ".");
            }

            Product product = productDao.getProductForUpdate(itemPayload.getProductId());
            if (product == null) {
                throw new ResponseStatusException(HttpStatus.NOT_FOUND, "Product not found for item " + itemPayload.getProductId() + ".");
            }

            int availableStock = product.getStock() == null ? 0 : product.getStock();
            int remainingQuantityToDeduct = requestedQuantity - reservedQuantity;
            if (availableStock < remainingQuantityToDeduct) {
                throw new ResponseStatusException(HttpStatus.BAD_REQUEST, product.getName() + " has only " + availableStock + " item(s) left in stock.");
            }

            BigDecimal originalUnitPrice = normalizeMoney(product.getPrice());
            BigDecimal productDiscountRate = normalizeDiscountRate(product.getDiscount());
            BigDecimal discountedUnitPrice = calculateDiscountedUnitPrice(originalUnitPrice, productDiscountRate);
            BigDecimal quantityValue = BigDecimal.valueOf(requestedQuantity);
            BigDecimal originalLineTotal = scaleCurrency(originalUnitPrice.multiply(quantityValue));
            BigDecimal discountedLineTotal = scaleCurrency(discountedUnitPrice.multiply(quantityValue));
            BigDecimal productDiscountLineTotal = scaleCurrency(originalLineTotal.subtract(discountedLineTotal));

            OrderItemPayload validatedItem = new OrderItemPayload();
            validatedItem.setProductId(product.getId());
            validatedItem.setProductName(product.getName());
            validatedItem.setProductImage(product.getImageUrl());
            validatedItem.setSize(itemPayload.getSize());
            validatedItem.setColor(itemPayload.getColor());
            validatedItem.setQuantity(requestedQuantity);
            validatedItem.setOriginalUnitPrice(originalUnitPrice.doubleValue());
            validatedItem.setDiscountedUnitPrice(discountedUnitPrice.doubleValue());
            validatedItem.setProductDiscountRate(productDiscountRate.doubleValue());
            validatedItem.setProductDiscountAmount(scaleCurrency(originalUnitPrice.subtract(discountedUnitPrice)).doubleValue());
            validatedItem.setOriginalLineTotal(originalLineTotal.doubleValue());
            validatedItem.setProductDiscountLineTotal(productDiscountLineTotal.doubleValue());
            validatedItem.setUnitPrice(discountedUnitPrice.doubleValue());
            validatedItem.setLineTotal(discountedLineTotal.doubleValue());
            validatedItem.setReservedQuantity(reservedQuantity);
            validatedItems.add(validatedItem);

            product.setStock(availableStock - remainingQuantityToDeduct);
            regularSubtotal = regularSubtotal.add(originalLineTotal);
            subtotalAfterProductDiscount = subtotalAfterProductDiscount.add(discountedLineTotal);
        }

        regularSubtotal = scaleCurrency(regularSubtotal);
        subtotalAfterProductDiscount = scaleCurrency(subtotalAfterProductDiscount);
        BigDecimal productDiscountTotal = scaleCurrency(regularSubtotal.subtract(subtotalAfterProductDiscount));

        return new ValidatedOrder(
                validatedItems,
                regularSubtotal.doubleValue(),
                productDiscountTotal.doubleValue(),
                subtotalAfterProductDiscount.doubleValue()
        );
    }

    private void restoreStock(List<OrderItemPayload> items) {
        for (OrderItemPayload item : items) {
            if (item.getProductId() == null || item.getQuantity() == null || item.getQuantity() <= 0) {
                continue;
            }

            Product product = productDao.getProductForUpdate(item.getProductId());
            if (product == null) {
                continue;
            }

            int currentStock = product.getStock() == null ? 0 : product.getStock();
            product.setStock(currentStock + item.getQuantity());
        }
    }

    private List<OrderItemPayload> mapExistingItems(List<OrderItem> orderItems) {
        List<OrderItemPayload> payloads = new ArrayList<>();
        for (OrderItem orderItem : orderItems) {
            OrderItemPayload payload = new OrderItemPayload();
            payload.setProductId(orderItem.getProduct() != null ? orderItem.getProduct().getId() : orderItem.getProductId());
            payload.setQuantity(orderItem.getQuantity());
            payload.setLineTotal(orderItem.getLineTotal());
            payloads.add(payload);
        }
        return payloads;
    }

    private Double normalizeAmount(Double value) {
        return value == null ? 0D : value;
    }

    private String normalizeString(String primaryValue, String fallbackValue) {
        String value = primaryValue != null && !primaryValue.trim().isEmpty() ? primaryValue.trim() : fallbackValue;
        return value == null ? "" : value.trim();
    }

    private String normalizeOrderStatus(String status) {
        String normalized = normalizeString(status, DEFAULT_ORDER_STATUS);
        String canonicalStatus = ORDER_STATUS_ALIASES.get(normalized.toLowerCase());
        if (canonicalStatus == null) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Invalid order status.");
        }
        return canonicalStatus;
    }

    private static Map<String, String> createOrderStatusAliases() {
        Map<String, String> aliases = new LinkedHashMap<>();
        aliases.put("pending", "Pending");
        aliases.put("pending review", "Pending");
        aliases.put("confirmed", "Confirmed");
        aliases.put("processing", "Processing");
        aliases.put("in progress", "Processing");
        aliases.put("shipped", "Shipped");
        aliases.put("delivered", "Delivered");
        aliases.put("cancelled", "Cancelled");
        return aliases;
    }

    private String resolvePaymentStatusForSnapshot(String paymentMethod, String orderStatus) {
        return orderStatusSideEffectService.resolvePaymentStatusForOrderStatus(
                normalizeString(orderStatus, DEFAULT_ORDER_STATUS)
        );
    }

    private void consumeCouponIfApplied(ValidatedOrder validatedOrder) {
        if (validatedOrder.couponApplicationResult() == null) {
            return;
        }

        couponService.markCouponAsUsed(validatedOrder.couponApplicationResult().coupon());
    }

    private void createInvoiceAndPaymentForOrder(Order order) {
        paymentService.syncPaymentForOrder(order, invoiceService.createInvoiceForOrder(order));
    }

    private ValidatedOrder buildValidatedOrder(List<OrderItemPayload> items, OrderRequest request) {
        double regularSubtotal = roundCurrency(items.stream()
                .mapToDouble(item -> normalizeAmount(item.getOriginalLineTotal()))
                .sum());
        double subtotalAfterProductDiscount = roundCurrency(items.stream()
                .mapToDouble(item -> normalizeAmount(item.getLineTotal()))
                .sum());
        double productDiscountTotal = roundCurrency(regularSubtotal - subtotalAfterProductDiscount);
        double tax = normalizeAmount(request.getTax());
        double shippingCost = normalizeAmount(request.getShippingCost());
        CouponApplicationResult couponApplicationResult = resolveCouponApplication(request.getCouponCode(), subtotalAfterProductDiscount, items);
        double couponDiscount = couponApplicationResult != null
                ? normalizeAmount(couponApplicationResult.discountAmount())
                : normalizeAmount(request.getCouponDiscount() != null ? request.getCouponDiscount() : request.getDiscount());
        String couponCode = couponApplicationResult != null ? couponApplicationResult.couponCode() : null;
        double finalTotal = roundCurrency(Math.max(subtotalAfterProductDiscount - couponDiscount + tax + shippingCost, 0D));
        LOGGER.info(
                "Validated order pricing: requestCouponCode={}, resolvedCouponCode={}, regularSubtotal={}, productDiscountTotal={}, subtotalAfterProductDiscount={}, couponDiscount={}, tax={}, shippingCost={}, finalTotal={}",
                request.getCouponCode(),
                couponCode,
                regularSubtotal,
                productDiscountTotal,
                subtotalAfterProductDiscount,
                couponDiscount,
                tax,
                shippingCost,
                finalTotal
        );
        return new ValidatedOrder(
                items,
                regularSubtotal,
                productDiscountTotal,
                subtotalAfterProductDiscount,
                tax,
                shippingCost,
                couponDiscount,
                couponCode,
                finalTotal,
                couponApplicationResult
        );
    }

    private CouponApplicationResult resolveCouponApplication(String couponCode, double subtotal, List<OrderItemPayload> items) {
        if (couponCode == null || couponCode.trim().isEmpty()) {
            return null;
        }

        return couponService.validateAndCalculateCoupon(couponCode, subtotal, items);
    }

    private record ValidatedOrder(
            List<OrderItemPayload> items,
            double regularSubtotal,
            double productDiscountTotal,
            double subtotalAfterProductDiscount,
            double tax,
            double shippingCost,
            double couponDiscount,
            String couponCode,
            double finalTotal,
            CouponApplicationResult couponApplicationResult
    ) {
        private ValidatedOrder(List<OrderItemPayload> items, double regularSubtotal, double productDiscountTotal, double subtotalAfterProductDiscount) {
            this(items, regularSubtotal, productDiscountTotal, subtotalAfterProductDiscount, 0D, 0D, 0D, null, subtotalAfterProductDiscount, null);
        }
    }

    private BigDecimal calculateDiscountedUnitPrice(BigDecimal originalPrice, BigDecimal discountRate) {
        BigDecimal multiplier = BigDecimal.ONE.subtract(discountRate.divide(BigDecimal.valueOf(100), 6, RoundingMode.HALF_UP));
        return scaleCurrency(originalPrice.multiply(multiplier));
    }

    private BigDecimal normalizeMoney(BigDecimal value) {
        return value == null ? BigDecimal.ZERO : value.max(BigDecimal.ZERO);
    }

    private BigDecimal normalizeDiscountRate(BigDecimal value) {
        BigDecimal normalized = value == null ? BigDecimal.ZERO : value;
        if (normalized.compareTo(BigDecimal.ZERO) < 0) {
            return BigDecimal.ZERO;
        }
        if (normalized.compareTo(BigDecimal.valueOf(100)) > 0) {
            return BigDecimal.valueOf(100);
        }
        return normalized;
    }

    private BigDecimal scaleCurrency(BigDecimal value) {
        return value.setScale(2, RoundingMode.HALF_UP);
    }

    private double roundCurrency(double value) {
        return scaleCurrency(BigDecimal.valueOf(value)).doubleValue();
    }
}
