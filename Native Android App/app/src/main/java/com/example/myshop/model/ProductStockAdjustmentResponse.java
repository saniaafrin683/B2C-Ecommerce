package com.example.myshop.model;

public class ProductStockAdjustmentResponse {
    private Long productId;
    private int quantity;
    private int stock;
    private String message;

    public Long getProductId() {
        return productId;
    }

    public int getQuantity() {
        return quantity;
    }

    public int getStock() {
        return stock;
    }

    public String getMessage() {
        return message;
    }
}
