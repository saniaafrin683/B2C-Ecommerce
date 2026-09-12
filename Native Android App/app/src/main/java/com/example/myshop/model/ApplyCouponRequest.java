package com.example.myshop.model;

import java.util.List;

public class ApplyCouponRequest {
    private String couponCode;
    private Double subtotal;
    private List<OrderItemRequest> orderItems;

    public ApplyCouponRequest(String couponCode, Double subtotal, List<OrderItemRequest> orderItems) {
        this.couponCode = couponCode;
        this.subtotal = subtotal;
        this.orderItems = orderItems;
    }
}
