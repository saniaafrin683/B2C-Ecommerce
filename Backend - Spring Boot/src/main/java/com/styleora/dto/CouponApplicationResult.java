package com.styleora.dto;

import com.styleora.model.Coupon;

public record CouponApplicationResult(
        Coupon coupon,
        String couponCode,
        String discountType,
        Double regularSubtotal,
        Double productDiscountTotal,
        Double subtotal,
        Double discountAmount,
        Double finalTotal
) {
}
