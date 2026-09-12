package com.example.myshop.model;

public class PaymentInitiateRequest {
    private Long orderId;

    public PaymentInitiateRequest(Long orderId) {
        this.orderId = orderId;
    }
}
