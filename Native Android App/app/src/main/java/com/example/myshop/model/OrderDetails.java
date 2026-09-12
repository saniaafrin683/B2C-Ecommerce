package com.example.myshop.model;

import java.util.List;

public class OrderDetails {
    private Long id;
    private Long databaseId;
    private String orderId;
    private String customerName;
    private String customerEmail;
    private String customerPhone;
    private String shippingAddress;
    private String paymentMethod;
    private String paymentStatus;
    private String orderStatus;
    private String shipmentStatus;
    private String trackingNumber;
    private Double totalAmount;
    private String createdAt;
    private List<OrderItemRequest> orderItems;

    public Long getId() {
        return id;
    }

    public Long getDatabaseId() {
        return databaseId != null ? databaseId : id;
    }

    public String getOrderId() {
        return orderId;
    }

    public String getCustomerName() {
        return customerName;
    }

    public String getCustomerEmail() {
        return customerEmail;
    }

    public String getCustomerPhone() {
        return customerPhone;
    }

    public String getShippingAddress() {
        return shippingAddress;
    }

    public String getPaymentMethod() {
        return paymentMethod;
    }

    public String getPaymentStatus() {
        return paymentStatus;
    }

    public String getOrderStatus() {
        return orderStatus;
    }

    public String getShipmentStatus() {
        return shipmentStatus;
    }

    public String getTrackingNumber() {
        return trackingNumber;
    }

    public Double getTotalAmount() {
        return totalAmount;
    }

    public String getCreatedAt() {
        return createdAt;
    }

    public List<OrderItemRequest> getOrderItems() {
        return orderItems;
    }
}
