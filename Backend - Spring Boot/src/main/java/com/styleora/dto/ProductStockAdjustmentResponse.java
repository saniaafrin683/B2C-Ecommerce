package com.styleora.dto;

public class ProductStockAdjustmentResponse {

    private Long productId;
    private Integer quantity;
    private Integer stock;
    private String message;

    public ProductStockAdjustmentResponse() {
    }

    public ProductStockAdjustmentResponse(Long productId, Integer quantity, Integer stock, String message) {
        this.productId = productId;
        this.quantity = quantity;
        this.stock = stock;
        this.message = message;
    }

    public Long getProductId() {
        return productId;
    }

    public void setProductId(Long productId) {
        this.productId = productId;
    }

    public Integer getQuantity() {
        return quantity;
    }

    public void setQuantity(Integer quantity) {
        this.quantity = quantity;
    }

    public Integer getStock() {
        return stock;
    }

    public void setStock(Integer stock) {
        this.stock = stock;
    }

    public String getMessage() {
        return message;
    }

    public void setMessage(String message) {
        this.message = message;
    }
}
