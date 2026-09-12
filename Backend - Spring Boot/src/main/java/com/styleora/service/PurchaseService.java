package com.styleora.service;
import com.styleora.dao.ProductDao;
import com.styleora.dao.PurchaseDao;
import com.styleora.dto.PurchaseItemRequest;
import com.styleora.dto.PurchaseItemResponse;
import com.styleora.dto.PurchaseRequest;
import com.styleora.dto.PurchaseResponse;
import com.styleora.model.Product;
import com.styleora.model.Purchase;
import com.styleora.model.PurchaseItem;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.util.StringUtils;
import org.springframework.web.server.ResponseStatusException;

import java.util.ArrayList;
import java.util.List;
import java.util.Objects;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

@Service
public class PurchaseService {

    private static final Pattern LEGACY_ITEM_PATTERN = Pattern.compile("\\{([^{}]+)}");

    private final PurchaseDao purchaseDao;
    private final ProductDao productDao;

    public PurchaseService(PurchaseDao purchaseDao, ProductDao productDao) {
        this.purchaseDao = purchaseDao;
        this.productDao = productDao;
    }

    public PurchaseResponse createPurchase(PurchaseRequest request) {
        ValidatedPurchase validatedPurchase = validateAndPrepare(request);

        Purchase purchase = new Purchase();
        applyPurchaseFields(purchase, validatedPurchase, request);
        purchase.setStockApplied(false);
        purchase.setPurchaseItems(buildPurchaseItems(purchase, validatedPurchase.items()));
        purchase.setItems(serializeLegacyItems(validatedPurchase.items()));

        purchaseDao.savePurchase(purchase);

        applyStockIfEligible(purchase);
        purchaseDao.savePurchase(purchase);

        return mapToResponse(purchaseDao.getPurchaseById(purchase.getId()));
    }

    public List<PurchaseResponse> getAllPurchases() {
        return purchaseDao.getAllPurchases().stream()
                .map(this::mapToResponse)
                .toList();
    }

    public PurchaseResponse getPurchaseById(Long id) {
        Purchase purchase = purchaseDao.getPurchaseById(id);
        return purchase == null ? null : mapToResponse(purchase);
    }

    public PurchaseResponse updatePurchase(Long id, PurchaseRequest request) {
        Purchase purchase = purchaseDao.getPurchaseByIdForUpdate(id);

        if (purchase == null) {
            return null;
        }

        ValidatedPurchase validatedPurchase = validateAndPrepare(request);

        if (Boolean.TRUE.equals(purchase.getStockApplied()) && itemsChanged(purchase.getPurchaseItems(), validatedPurchase.items())) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Purchase items cannot be changed after stock has been applied.");
        }

        applyPurchaseFields(purchase, validatedPurchase, request);

        if (!Boolean.TRUE.equals(purchase.getStockApplied())) {
            purchase.setPurchaseItems(buildPurchaseItems(purchase, validatedPurchase.items()));
            purchase.setItems(serializeLegacyItems(validatedPurchase.items()));
        }

        applyStockIfEligible(purchase);
        purchaseDao.savePurchase(purchase);

        return mapToResponse(purchaseDao.getPurchaseById(id));
    }

    public boolean deletePurchase(Long id) {
        Purchase purchase = purchaseDao.getPurchaseByIdForUpdate(id);
        if (purchase == null) {
            return false;
        }

        if (Boolean.TRUE.equals(purchase.getStockApplied())) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Applied purchases cannot be deleted because stock has already been increased.");
        }

        return purchaseDao.deletePurchase(purchase);
    }

    private void applyPurchaseFields(Purchase purchase, ValidatedPurchase validatedPurchase, PurchaseRequest request) {
        purchase.setPurchaseId(normalizeString(request.getPurchaseId()));
        purchase.setSupplierName(normalizeString(request.getSupplierName()));
        purchase.setOrderBy(purchase.getSupplierName());
        purchase.setSupplierEmail(normalizeString(request.getSupplierEmail()));
        purchase.setSupplierPhone(normalizeString(request.getSupplierPhone()));
        purchase.setSupplierAddress(normalizeString(request.getSupplierAddress()));
        purchase.setPurchaseStatus(validatedPurchase.status());
        purchase.setPurchaseDate(request.getPurchaseDate());
        purchase.setSubtotal(validatedPurchase.subtotal());
        purchase.setDiscount(validatedPurchase.discount());
        purchase.setTax(validatedPurchase.tax());
        purchase.setShippingCost(validatedPurchase.shippingCost());
        purchase.setTotal(validatedPurchase.totalAmount());
        purchase.setPaymentMethod(normalizeString(request.getPaymentMethod()));
        purchase.setPaymentStatus(normalizeString(request.getPaymentStatus()));
        purchase.setPaidAmount(validatedPurchase.paidAmount());
        purchase.setDueAmount(validatedPurchase.dueAmount());
        purchase.setNotes(normalizeString(request.getNotes()));
    }

    private ValidatedPurchase validateAndPrepare(PurchaseRequest request) {
        if (request == null) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Purchase payload is required.");
        }

        String supplierName = normalizeString(request.getSupplierName());
        if (!StringUtils.hasText(supplierName)) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Supplier name is required.");
        }
        if (request.getPurchaseDate() == null) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Purchase date is required.");
        }

        List<PurchaseItemRequest> itemRequests = request.getItems() == null ? List.of() : request.getItems();
        if (itemRequests.isEmpty()) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "At least one purchase item is required.");
        }

        List<PreparedPurchaseItem> items = new ArrayList<>();
        double subtotal = 0D;

        for (PurchaseItemRequest itemRequest : itemRequests) {
            if (itemRequest == null || itemRequest.getProductId() == null) {
                throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Each purchase item must include a product.");
            }

            Product product = productDao.getProductById(itemRequest.getProductId());
            if (product == null) {
                throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Product not found for item: " + itemRequest.getProductId());
            }

            int quantity = normalizePositiveQuantity(itemRequest.getQuantity());
            double unitPrice = normalizeNonNegativeAmount(itemRequest.getUnitPrice());
            double lineSubtotal = quantity * unitPrice;

            items.add(new PreparedPurchaseItem(product, quantity, unitPrice, lineSubtotal));
            subtotal += lineSubtotal;
        }

        double discount = normalizeNonNegativeAmount(request.getDiscount());
        double tax = normalizeNonNegativeAmount(request.getTax());
        double shippingCost = normalizeNonNegativeAmount(request.getShippingCost());
        double totalAmount = subtotal - discount + tax + shippingCost;
        if (totalAmount < 0) {
            totalAmount = 0D;
        }

        double paidAmount = normalizeNonNegativeAmount(request.getPaidAmount());
        double dueAmount = Math.max(totalAmount - paidAmount, 0D);
        String status = normalizeStatus(request.getPurchaseStatus());

        return new ValidatedPurchase(supplierName, status, subtotal, discount, tax, shippingCost, totalAmount, paidAmount, dueAmount, items);
    }

    private List<PurchaseItem> buildPurchaseItems(Purchase purchase, List<PreparedPurchaseItem> preparedItems) {
        List<PurchaseItem> purchaseItems = new ArrayList<>();

        for (PreparedPurchaseItem preparedItem : preparedItems) {
            PurchaseItem purchaseItem = new PurchaseItem();
            purchaseItem.setPurchase(purchase);
            purchaseItem.setProduct(preparedItem.product());
            purchaseItem.setQuantity(preparedItem.quantity());
            purchaseItem.setUnitPrice(preparedItem.unitPrice());
            purchaseItem.setSubtotal(preparedItem.subtotal());
            purchaseItems.add(purchaseItem);
        }

        return purchaseItems;
    }

    private void applyStockIfEligible(Purchase purchase) {
        if (purchase == null || Boolean.TRUE.equals(purchase.getStockApplied()) || !isStockApplyingStatus(purchase.getPurchaseStatus())) {
            return;
        }

        List<PurchaseItem> purchaseItems = purchase.getPurchaseItems() == null ? List.of() : purchase.getPurchaseItems();
        if (purchaseItems.isEmpty()) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Completed or received purchases must include item rows.");
        }

        for (PurchaseItem purchaseItem : purchaseItems) {
            Long productId = purchaseItem.getProduct() != null ? purchaseItem.getProduct().getId() : null;
            int quantity = purchaseItem.getQuantity() == null ? 0 : purchaseItem.getQuantity();
            boolean updated = productDao.increaseStock(productId, quantity);

            if (!updated) {
                throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Failed to increase stock for product id " + productId + ".");
            }
        }

        purchase.setStockApplied(true);
    }

    private PurchaseResponse mapToResponse(Purchase purchase) {
        PurchaseResponse response = new PurchaseResponse();
        response.setId(purchase.getId());
        response.setPurchaseId(purchase.getPurchaseId());
        response.setSupplierName(firstNonBlank(purchase.getSupplierName(), purchase.getOrderBy()));
        response.setSupplierEmail(purchase.getSupplierEmail());
        response.setSupplierPhone(purchase.getSupplierPhone());
        response.setSupplierAddress(purchase.getSupplierAddress());
        response.setPurchaseStatus(normalizeStatus(purchase.getPurchaseStatus()));
        response.setPurchaseDate(purchase.getPurchaseDate());
        response.setSubtotal(normalizeAmount(purchase.getSubtotal()));
        response.setDiscount(normalizeAmount(purchase.getDiscount()));
        response.setTax(normalizeAmount(purchase.getTax()));
        response.setShippingCost(normalizeAmount(purchase.getShippingCost()));
        response.setTotalAmount(normalizeAmount(purchase.getTotal()));
        response.setPaymentMethod(purchase.getPaymentMethod());
        response.setPaymentStatus(purchase.getPaymentStatus());
        response.setPaidAmount(normalizeAmount(purchase.getPaidAmount()));
        response.setDueAmount(normalizeAmount(purchase.getDueAmount()));
        response.setNotes(purchase.getNotes());
        response.setStockApplied(Boolean.TRUE.equals(purchase.getStockApplied()));
        response.setItems(resolveResponseItems(purchase));
        return response;
    }

    private List<PurchaseItemResponse> resolveResponseItems(Purchase purchase) {
        if (purchase.getPurchaseItems() != null && !purchase.getPurchaseItems().isEmpty()) {
            return purchase.getPurchaseItems().stream().map((item) -> {
                PurchaseItemResponse response = new PurchaseItemResponse();
                response.setId(item.getId());
                response.setProductId(item.getProduct() != null ? item.getProduct().getId() : null);
                response.setProductName(item.getProduct() != null ? item.getProduct().getName() : "");
                response.setCategory(item.getProduct() != null ? item.getProduct().getCategory() : "");
                response.setQuantity(item.getQuantity() == null ? 0 : item.getQuantity());
                response.setUnitPrice(normalizeAmount(item.getUnitPrice()));
                response.setSubtotal(normalizeAmount(item.getSubtotal()));
                return response;
            }).toList();
        }

        return parseLegacyItems(purchase.getItems());
    }

    private List<PurchaseItemResponse> parseLegacyItems(String itemsJson) {
        if (!StringUtils.hasText(itemsJson)) {
            return List.of();
        }

        List<PurchaseItemResponse> responses = new ArrayList<>();
        Matcher matcher = LEGACY_ITEM_PATTERN.matcher(itemsJson);

        while (matcher.find()) {
            String itemJson = matcher.group(1);
            PurchaseItemResponse response = new PurchaseItemResponse();
            response.setProductName(extractJsonString(itemJson, "product"));
            response.setQuantity(extractJsonInteger(itemJson, "quantity"));
            response.setUnitPrice(extractJsonDouble(itemJson, "unitPrice", extractJsonDouble(itemJson, "unitCost", 0D)));
            response.setSubtotal(extractJsonDouble(itemJson, "subtotal", extractJsonDouble(itemJson, "total", 0D)));
            response.setCategory("");
            responses.add(response);
        }

        return responses;
    }

    private String serializeLegacyItems(List<PreparedPurchaseItem> items) {
        StringBuilder builder = new StringBuilder("[");

        for (int index = 0; index < items.size(); index++) {
            PreparedPurchaseItem item = items.get(index);
            if (index > 0) {
                builder.append(',');
            }

            builder.append('{')
                    .append("\"productId\":").append(item.product().getId()).append(',')
                    .append("\"product\":\"").append(escapeJson(item.product().getName())).append("\",")
                    .append("\"sku\":\"").append(escapeJson(item.product().getTagNumber())).append("\",")
                    .append("\"quantity\":").append(item.quantity()).append(',')
                    .append("\"unitCost\":").append(item.unitPrice()).append(',')
                    .append("\"subtotal\":").append(item.subtotal()).append(',')
                    .append("\"total\":").append(item.subtotal())
                    .append('}');
        }

        builder.append(']');
        return builder.toString();
    }

    private boolean itemsChanged(List<PurchaseItem> existingItems, List<PreparedPurchaseItem> incomingItems) {
        List<PurchaseItem> safeExistingItems = existingItems == null ? List.of() : existingItems;
        if (safeExistingItems.size() != incomingItems.size()) {
            return true;
        }

        for (int index = 0; index < safeExistingItems.size(); index++) {
            PurchaseItem existingItem = safeExistingItems.get(index);
            PreparedPurchaseItem incomingItem = incomingItems.get(index);

            Long existingProductId = existingItem.getProduct() != null ? existingItem.getProduct().getId() : null;
            if (!Objects.equals(existingProductId, incomingItem.product().getId())) {
                return true;
            }
            if (!Objects.equals(existingItem.getQuantity(), incomingItem.quantity())) {
                return true;
            }
            if (Double.compare(normalizeAmount(existingItem.getUnitPrice()), incomingItem.unitPrice()) != 0) {
                return true;
            }
        }

        return false;
    }

    private boolean isStockApplyingStatus(String status) {
        String normalizedStatus = normalizeStatus(status);
        return "Received".equalsIgnoreCase(normalizedStatus) || "Completed".equalsIgnoreCase(normalizedStatus);
    }

    private String normalizeStatus(String status) {
        String normalizedStatus = normalizeString(status);
        if (!StringUtils.hasText(normalizedStatus)) {
            return "Pending";
        }

        String lowerCaseStatus = normalizedStatus.toLowerCase();
        return switch (lowerCaseStatus) {
            case "received" -> "Received";
            case "completed", "complete" -> "Completed";
            case "cancelled", "canceled" -> "Cancelled";
            default -> "Pending";
        };
    }

    private int normalizePositiveQuantity(Integer quantity) {
        int normalizedQuantity = quantity == null ? 0 : quantity;
        if (normalizedQuantity <= 0) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Quantity must be at least 1.");
        }
        return normalizedQuantity;
    }

    private double normalizeNonNegativeAmount(Double value) {
        double normalizedValue = normalizeAmount(value);
        if (normalizedValue < 0) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Amounts cannot be negative.");
        }
        return normalizedValue;
    }

    private double normalizeAmount(Double value) {
        return value == null ? 0D : Math.max(value, 0D);
    }

    private String normalizeString(String value) {
        return StringUtils.hasText(value) ? value.trim() : null;
    }

    private String firstNonBlank(String first, String second) {
        if (StringUtils.hasText(first)) {
            return first.trim();
        }
        return normalizeString(second);
    }

    private String extractJsonString(String json, String key) {
        Matcher matcher = Pattern.compile("\"" + Pattern.quote(key) + "\"\\s*:\\s*\"([^\"]*)\"").matcher(json);
        return matcher.find() ? matcher.group(1) : "";
    }

    private Integer extractJsonInteger(String json, String key) {
        Matcher matcher = Pattern.compile("\"" + Pattern.quote(key) + "\"\\s*:\\s*(-?\\d+)").matcher(json);
        return matcher.find() ? Integer.parseInt(matcher.group(1)) : 0;
    }

    private Double extractJsonDouble(String json, String key, Double fallback) {
        Matcher matcher = Pattern.compile("\"" + Pattern.quote(key) + "\"\\s*:\\s*(-?\\d+(?:\\.\\d+)?)").matcher(json);
        return matcher.find() ? Double.parseDouble(matcher.group(1)) : fallback;
    }

    private String escapeJson(String value) {
        if (value == null) {
            return "";
        }

        return value.replace("\\", "\\\\").replace("\"", "\\\"");
    }

    private record PreparedPurchaseItem(Product product, Integer quantity, Double unitPrice, Double subtotal) {}

    private record ValidatedPurchase(
            String supplierName,
            String status,
            Double subtotal,
            Double discount,
            Double tax,
            Double shippingCost,
            Double totalAmount,
            Double paidAmount,
            Double dueAmount,
            List<PreparedPurchaseItem> items
    ) {}
}
