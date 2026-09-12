package com.styleora.dto;

public class OrderItemPayload {
    private Long id;
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

    public OrderItemPayload() {
    }

    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public Long getProductId() {
        return productId;
    }

    public void setProductId(Long productId) {
        this.productId = productId;
    }

    public String getProductName() {
        return productName;
    }

    public void setProductName(String productName) {
        this.productName = productName;
    }

    public String getProductImage() {
        return productImage;
    }

    public void setProductImage(String productImage) {
        this.productImage = productImage;
    }

    public String getSize() {
        return size;
    }

    public void setSize(String size) {
        this.size = size;
    }

    public String getColor() {
        return color;
    }

    public void setColor(String color) {
        this.color = color;
    }

    public Double getOriginalUnitPrice() {
        return originalUnitPrice;
    }

    public void setOriginalUnitPrice(Double originalUnitPrice) {
        this.originalUnitPrice = originalUnitPrice;
    }

    public Double getDiscountedUnitPrice() {
        return discountedUnitPrice;
    }

    public void setDiscountedUnitPrice(Double discountedUnitPrice) {
        this.discountedUnitPrice = discountedUnitPrice;
    }

    public Double getProductDiscountRate() {
        return productDiscountRate;
    }

    public void setProductDiscountRate(Double productDiscountRate) {
        this.productDiscountRate = productDiscountRate;
    }

    public Double getProductDiscountAmount() {
        return productDiscountAmount;
    }

    public void setProductDiscountAmount(Double productDiscountAmount) {
        this.productDiscountAmount = productDiscountAmount;
    }

    public Double getOriginalLineTotal() {
        return originalLineTotal;
    }

    public void setOriginalLineTotal(Double originalLineTotal) {
        this.originalLineTotal = originalLineTotal;
    }

    public Double getProductDiscountLineTotal() {
        return productDiscountLineTotal;
    }

    public void setProductDiscountLineTotal(Double productDiscountLineTotal) {
        this.productDiscountLineTotal = productDiscountLineTotal;
    }

    public Double getUnitPrice() {
        return unitPrice;
    }

    public void setUnitPrice(Double unitPrice) {
        this.unitPrice = unitPrice;
    }

    public Integer getQuantity() {
        return quantity;
    }

    public void setQuantity(Integer quantity) {
        this.quantity = quantity;
    }

    public Integer getReservedQuantity() {
        return reservedQuantity;
    }

    public void setReservedQuantity(Integer reservedQuantity) {
        this.reservedQuantity = reservedQuantity;
    }

    public Double getLineTotal() {
        return lineTotal;
    }

    public void setLineTotal(Double lineTotal) {
        this.lineTotal = lineTotal;
    }
}
