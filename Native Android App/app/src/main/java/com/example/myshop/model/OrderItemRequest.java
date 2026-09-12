package com.example.myshop.model;

public class OrderItemRequest {
    private Long productId;
    private String productName;
    private String productImage;
    private String size;
    private String color;
    private Double originalUnitPrice;
    private Double discountedUnitPrice;
    private Double productDiscountRate;
    private Double productDiscountAmount;
    private Double originalLineTotal;
    private Double productDiscountLineTotal;
    private Double unitPrice;
    private Integer quantity;
    private Integer reservedQuantity;
    private Double lineTotal;

    public OrderItemRequest() {
    }

    public OrderItemRequest(CartItem item, double originalUnitPrice, double discountedUnitPrice) {
        this.productId = item.getProductId();
        this.productName = item.getName();
        this.productImage = item.getImageUrl();
        this.size = item.getSize();
        this.color = "";
        this.originalUnitPrice = originalUnitPrice;
        this.discountedUnitPrice = discountedUnitPrice;
        this.productDiscountRate = item.getDiscount() == null ? 0.0 : item.getDiscount().doubleValue();
        this.productDiscountAmount = originalUnitPrice - discountedUnitPrice;
        this.originalLineTotal = originalUnitPrice * item.getQuantity();
        this.productDiscountLineTotal = this.productDiscountAmount * item.getQuantity();
        this.unitPrice = discountedUnitPrice;
        this.quantity = item.getQuantity();
        this.reservedQuantity = item.getQuantity();
        this.lineTotal = discountedUnitPrice * item.getQuantity();
    }

    public Long getProductId() {
        return productId;
    }

    public String getProductName() {
        return productName;
    }

    public String getProductImage() {
        return productImage;
    }

    public String getSize() {
        return size;
    }

    public String getColor() {
        return color;
    }

    public Double getOriginalUnitPrice() {
        return originalUnitPrice;
    }

    public Double getDiscountedUnitPrice() {
        return discountedUnitPrice;
    }

    public Double getProductDiscountRate() {
        return productDiscountRate;
    }

    public Double getProductDiscountAmount() {
        return productDiscountAmount;
    }

    public Double getOriginalLineTotal() {
        return originalLineTotal;
    }

    public Double getProductDiscountLineTotal() {
        return productDiscountLineTotal;
    }

    public Double getUnitPrice() {
        return unitPrice;
    }

    public Integer getQuantity() {
        return quantity;
    }

    public Integer getReservedQuantity() {
        return reservedQuantity;
    }

    public Double getLineTotal() {
        return lineTotal;
    }
}
