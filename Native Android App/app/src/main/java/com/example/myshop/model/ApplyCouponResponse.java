package com.example.myshop.model;

public class ApplyCouponResponse {
    private String couponCode;
    private String discountType;
    private Double discountAmount;
    private Double subtotal;
    private Double regularSubtotal;
    private Double productDiscountTotal;
    private Double subtotalAfterProductDiscount;
    private Double couponDiscount;
    private Double finalTotal;
    private String message;

    public String getCouponCode() {
        return couponCode;
    }

    public String getDiscountType() {
        return discountType;
    }

    public Double getDiscountAmount() {
        return discountAmount;
    }

    public Double getSubtotal() {
        return subtotal;
    }

    public Double getRegularSubtotal() {
        return regularSubtotal;
    }

    public Double getProductDiscountTotal() {
        return productDiscountTotal;
    }

    public Double getSubtotalAfterProductDiscount() {
        return subtotalAfterProductDiscount;
    }

    public Double getCouponDiscount() {
        return couponDiscount;
    }

    public Double getFinalTotal() {
        return finalTotal;
    }

    public String getMessage() {
        return message;
    }
}
