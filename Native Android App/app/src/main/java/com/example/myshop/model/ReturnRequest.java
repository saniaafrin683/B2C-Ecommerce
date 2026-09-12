package com.example.myshop.model;

public class ReturnRequest {
    private Long id;
    private Long orderId;
    private Long customerId;
    private Long productId;
    private String reason;
    private String note;
    private String status;
    private String requestedAt;
    private String updatedAt;
    private String orderReference;
    private String customerName;

    public Long getId() {
        return id;
    }

    public Long getOrderId() {
        return orderId;
    }

    public Long getCustomerId() {
        return customerId;
    }

    public Long getProductId() {
        return productId;
    }

    public String getReason() {
        return reason;
    }

    public String getNote() {
        return note;
    }

    public String getStatus() {
        return status;
    }

    public String getRequestedAt() {
        return requestedAt;
    }

    public String getUpdatedAt() {
        return updatedAt;
    }

    public String getOrderReference() {
        return orderReference;
    }

    public String getCustomerName() {
        return customerName;
    }
}
