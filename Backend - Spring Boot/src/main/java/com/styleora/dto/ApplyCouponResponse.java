package com.styleora.dto;

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

    public ApplyCouponResponse() {
    }

    public String getCouponCode() {
        return couponCode;
    }

    public void setCouponCode(String couponCode) {
        this.couponCode = couponCode;
    }

    public String getDiscountType() {
        return discountType;
    }

    public void setDiscountType(String discountType) {
        this.discountType = discountType;
    }

    public Double getDiscountAmount() {
        return discountAmount;
    }

    public void setDiscountAmount(Double discountAmount) {
        this.discountAmount = discountAmount;
    }

    public Double getSubtotal() {
        return subtotal;
    }

    public void setSubtotal(Double subtotal) {
        this.subtotal = subtotal;
    }

    public Double getRegularSubtotal() {
        return regularSubtotal;
    }

    public void setRegularSubtotal(Double regularSubtotal) {
        this.regularSubtotal = regularSubtotal;
    }

    public Double getProductDiscountTotal() {
        return productDiscountTotal;
    }

    public void setProductDiscountTotal(Double productDiscountTotal) {
        this.productDiscountTotal = productDiscountTotal;
    }

    public Double getSubtotalAfterProductDiscount() {
        return subtotalAfterProductDiscount;
    }

    public void setSubtotalAfterProductDiscount(Double subtotalAfterProductDiscount) {
        this.subtotalAfterProductDiscount = subtotalAfterProductDiscount;
    }

    public Double getCouponDiscount() {
        return couponDiscount;
    }

    public void setCouponDiscount(Double couponDiscount) {
        this.couponDiscount = couponDiscount;
    }

    public Double getFinalTotal() {
        return finalTotal;
    }

    public void setFinalTotal(Double finalTotal) {
        this.finalTotal = finalTotal;
    }

    public String getMessage() {
        return message;
    }

    public void setMessage(String message) {
        this.message = message;
    }
}
