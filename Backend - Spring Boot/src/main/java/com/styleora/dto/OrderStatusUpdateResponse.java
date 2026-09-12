package com.styleora.dto;

import com.fasterxml.jackson.annotation.JsonProperty;

public class OrderStatusUpdateResponse {

    private Long id;
    private String orderId;
    private String status;
    private String paymentStatus;

    public OrderStatusUpdateResponse() {
    }

    public OrderStatusUpdateResponse(Long id, String orderId, String status) {
        this.id = id;
        this.orderId = orderId;
        this.status = status;
    }

    public OrderStatusUpdateResponse(Long id, String orderId, String status, String paymentStatus) {
        this.id = id;
        this.orderId = orderId;
        this.status = status;
        this.paymentStatus = paymentStatus;
    }

    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public String getOrderId() {
        return orderId;
    }

    public void setOrderId(String orderId) {
        this.orderId = orderId;
    }

    public String getStatus() {
        return status;
    }

    public void setStatus(String status) {
        this.status = status;
    }

    public String getPaymentStatus() {
        return paymentStatus;
    }

    public void setPaymentStatus(String paymentStatus) {
        this.paymentStatus = paymentStatus;
    }

    @JsonProperty("orderStatus")
    public String getOrderStatus() {
        return status;
    }
}
