package com.example.myshop.model;

public class ProductStockAdjustmentRequest {
    private int quantity;

    public ProductStockAdjustmentRequest(int quantity) {
        this.quantity = quantity;
    }

    public int getQuantity() {
        return quantity;
    }
}
