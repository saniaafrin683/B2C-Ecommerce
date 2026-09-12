package com.example.myshop.model;

import java.util.List;

public class OrderRequest {
    private String orderId;
    private String createdAt;
    private String customerName;
    private String customerEmail;
    private String customerPhone;
    private String shippingAddress;
    private String billingAddress;
    private String priority;
    private Double subtotal;
    private Double regularSubtotal;
    private Double productDiscountTotal;
    private Double subtotalAfterProductDiscount;
    private Double tax;
    private Double discount;
    private Double couponDiscount;
    private Double shippingCost;
    private String couponCode;
    private Double totalAmount;
    private String paymentMethod;
    private String paymentStatus;
    private String orderStatus;
    private List<OrderItemRequest> orderItems;

    public OrderRequest(
            String orderId,
            String createdAt,
            String customerName,
            String customerEmail,
            String customerPhone,
            String shippingAddress,
            Double regularSubtotal,
            Double productDiscountTotal,
            Double subtotalAfterProductDiscount,
            Double couponDiscount,
            Double shippingCost,
            String couponCode,
            Double totalAmount,
            String paymentMethod,
            List<OrderItemRequest> orderItems
    ) {
        this.orderId = orderId;
        this.createdAt = createdAt;
        this.customerName = customerName;
        this.customerEmail = customerEmail;
        this.customerPhone = customerPhone;
        this.shippingAddress = shippingAddress;
        this.billingAddress = shippingAddress;
        this.priority = "NORMAL";
        this.subtotal = subtotalAfterProductDiscount;
        this.regularSubtotal = regularSubtotal;
        this.productDiscountTotal = productDiscountTotal;
        this.subtotalAfterProductDiscount = subtotalAfterProductDiscount;
        this.tax = 0.0;
        this.discount = couponDiscount;
        this.couponDiscount = couponDiscount;
        this.shippingCost = shippingCost;
        this.couponCode = couponCode;
        this.totalAmount = totalAmount;
        this.paymentMethod = paymentMethod;
        this.paymentStatus = "Pending";
        this.orderStatus = "Pending";
        this.orderItems = orderItems;
    }
}
