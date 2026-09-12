package com.styleora.dto;

import java.util.ArrayList;
import java.util.List;

public class ApplyCouponRequest {

    private String couponCode;
    private Double subtotal;
    private List<OrderItemPayload> orderItems = new ArrayList<>();

    public ApplyCouponRequest() {
    }

    public String getCouponCode() {
        return couponCode;
    }

    public void setCouponCode(String couponCode) {
        this.couponCode = couponCode;
    }

    public Double getSubtotal() {
        return subtotal;
    }

    public void setSubtotal(Double subtotal) {
        this.subtotal = subtotal;
    }

    public List<OrderItemPayload> getOrderItems() {
        return orderItems;
    }

    public void setOrderItems(List<OrderItemPayload> orderItems) {
        this.orderItems = orderItems == null ? new ArrayList<>() : orderItems;
    }
}
