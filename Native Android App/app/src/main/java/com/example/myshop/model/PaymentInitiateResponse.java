package com.example.myshop.model;

public class PaymentInitiateResponse {
    private Long orderId;
    private String orderReference;
    private String transactionId;
    private String paymentUrl;
    private String message;

    public Long getOrderId() {
        return orderId;
    }

    public String getOrderReference() {
        return orderReference;
    }

    public String getTransactionId() {
        return transactionId;
    }

    public String getPaymentUrl() {
        return paymentUrl;
    }

    public String getMessage() {
        return message;
    }
}
