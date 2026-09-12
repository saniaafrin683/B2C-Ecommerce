package com.styleora.service;

import com.styleora.dao.CouponDao;
import com.styleora.dao.ProductDao;
import com.styleora.dto.ApplyCouponResponse;
import com.styleora.dto.CouponApplicationResult;
import com.styleora.dto.OrderItemPayload;
import com.styleora.model.Coupon;
import com.styleora.model.Product;
import jakarta.transaction.Transactional;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;
import java.util.Locale;

@Service
public class CouponService {

    private static final Logger LOGGER = LoggerFactory.getLogger(CouponService.class);

    private final CouponDao couponDao;
    private final ProductDao productDao;

    public CouponService(CouponDao couponDao, ProductDao productDao) {
        this.couponDao = couponDao;
        this.productDao = productDao;
    }

    public Coupon createCoupon(Coupon coupon) {
        LocalDate today = LocalDate.now();
        if (coupon.getCreatedAt() == null) {
            coupon.setCreatedAt(today);
        }
        coupon.setUpdatedAt(today);
        if (coupon.getUsedCount() == null) {
            coupon.setUsedCount(0);
        }
        return couponDao.saveCoupon(coupon);
    }

    public List<Coupon> getAllCoupons() {
        return couponDao.getAllCoupons();
    }

    public Coupon getCouponById(Long id) {
        return couponDao.getCouponById(id);
    }

    public ApplyCouponResponse applyCoupon(String couponCode, Double subtotal, List<OrderItemPayload> orderItems) {
        CouponApplicationResult applicationResult = validateAndCalculateCoupon(couponCode, subtotal, orderItems);

        ApplyCouponResponse response = new ApplyCouponResponse();
        response.setCouponCode(applicationResult.couponCode());
        response.setDiscountType(applicationResult.discountType());
        response.setSubtotal(applicationResult.subtotal());
        response.setRegularSubtotal(applicationResult.regularSubtotal());
        response.setProductDiscountTotal(applicationResult.productDiscountTotal());
        response.setSubtotalAfterProductDiscount(applicationResult.subtotal());
        response.setDiscountAmount(applicationResult.discountAmount());
        response.setCouponDiscount(applicationResult.discountAmount());
        response.setFinalTotal(applicationResult.finalTotal());
        response.setMessage("Coupon applied successfully.");
        return response;
    }

    public CouponApplicationResult validateAndCalculateCoupon(String couponCode, Double subtotal) {
        return validateAndCalculateCoupon(couponCode, subtotal, new ArrayList<>());
    }

    public CouponApplicationResult validateAndCalculateCoupon(String couponCode, Double subtotal, List<OrderItemPayload> orderItems) {
        String normalizedCode = normalizeCouponCode(couponCode);
        if (normalizedCode == null) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Coupon code is required.");
        }

        PricingBreakdown pricingBreakdown = resolvePricingBreakdown(subtotal, orderItems);
        double normalizedSubtotal = pricingBreakdown.subtotalAfterProductDiscount();
        if (normalizedSubtotal <= 0D) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "A valid order subtotal is required to apply a coupon.");
        }

        Coupon coupon = couponDao.findByCouponCode(normalizedCode);
        if (coupon == null) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Invalid coupon code.");
        }

        validateCouponState(coupon, normalizedSubtotal);

        double discountAmount = calculateDiscountAmount(coupon, normalizedSubtotal);
        double finalTotal = Math.max(normalizedSubtotal - discountAmount, 0D);

        return new CouponApplicationResult(
                coupon,
                normalizedCode,
                coupon.getDiscountType(),
                pricingBreakdown.regularSubtotal(),
                pricingBreakdown.productDiscountTotal(),
                normalizedSubtotal,
                discountAmount,
                finalTotal
        );
    }

    public void markCouponAsUsed(Coupon coupon) {
        if (coupon == null) {
            return;
        }

        couponDao.incrementUsedCount(coupon.getCouponCode());
    }

    public Coupon updateCoupon(Long id, Coupon coupon) {
        Coupon existingCoupon = couponDao.getCouponById(id);
        if (existingCoupon == null) {
            return null;
        }

        coupon.setCreatedAt(existingCoupon.getCreatedAt());
        coupon.setUpdatedAt(LocalDate.now());
        return couponDao.updateCoupon(id, coupon);
    }

    @Transactional
    public boolean deleteCoupon(Long id) {
        LOGGER.info("Delete coupon request received for id={}", id);
        boolean deleted = couponDao.deleteCoupon(id);
        LOGGER.info("Delete coupon request completed for id={}, deleted={}", id, deleted);
        return deleted;
    }

    private void validateCouponState(Coupon coupon, double subtotal) {
        LocalDate today = LocalDate.now();
        String normalizedStatus = normalizeStatus(coupon.getStatus());

        if ("INACTIVE".equals(normalizedStatus)) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "This coupon is inactive.");
        }

        if ("EXPIRED".equals(normalizedStatus)) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "This coupon has expired.");
        }

        if (coupon.getStartDate() != null && today.isBefore(coupon.getStartDate())) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "This coupon is not active yet.");
        }

        if (coupon.getEndDate() != null && today.isAfter(coupon.getEndDate())) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "This coupon has expired.");
        }

        if ("SCHEDULED".equals(normalizedStatus) && coupon.getStartDate() != null && !today.isBefore(coupon.getStartDate())) {
            normalizedStatus = "ACTIVE";
        }

        if (!"ACTIVE".equals(normalizedStatus) && !"SCHEDULED".equals(normalizedStatus)) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "This coupon is not active.");
        }

        int usageLimit = coupon.getUsageLimit() == null ? 0 : coupon.getUsageLimit();
        int usedCount = coupon.getUsedCount() == null ? 0 : coupon.getUsedCount();
        if (usageLimit > 0 && usedCount >= usageLimit) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "This coupon has reached its usage limit.");
        }

        double minimumOrderAmount = normalizeAmount(coupon.getMinimumOrderAmount());
        if (minimumOrderAmount > 0D && subtotal < minimumOrderAmount) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST,
                    "This coupon requires a minimum order amount of " + minimumOrderAmount + "."
            );
        }
    }

    private double calculateDiscountAmount(Coupon coupon, double subtotal) {
        double discountValue = normalizeAmount(coupon.getDiscountValue());
        if (discountValue <= 0D) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "This coupon is not configured with a valid discount.");
        }

        String discountType = normalizeDiscountType(coupon.getDiscountType());
        double calculatedDiscount;

        if ("PERCENTAGE".equals(discountType)) {
            calculatedDiscount = subtotal * (discountValue / 100D);
        } else if ("FIXED_AMOUNT".equals(discountType)) {
            calculatedDiscount = discountValue;
        } else {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "This coupon has an unsupported discount type.");
        }

        return Math.min(Math.max(calculatedDiscount, 0D), subtotal);
    }

    private String normalizeCouponCode(String couponCode) {
        if (couponCode == null || couponCode.trim().isEmpty()) {
            return null;
        }

        return couponCode.trim();
    }

    private String normalizeStatus(String status) {
        if (status == null || status.trim().isEmpty()) {
            return "";
        }

        return status.trim().replace(' ', '_').toUpperCase(Locale.ROOT);
    }

    private String normalizeDiscountType(String discountType) {
        if (discountType == null || discountType.trim().isEmpty()) {
            return "";
        }

        String normalized = discountType.trim()
                .replaceAll("([a-z])([A-Z])", "$1 $2")
                .replace('-', ' ')
                .replace('_', ' ')
                .replaceAll("\\s+", " ")
                .trim()
                .toLowerCase(Locale.ROOT);
        if ("fixed amount".equals(normalized) || "fixed".equals(normalized) || "flat".equals(normalized)) {
            return "FIXED_AMOUNT";
        }

        if ("percentage".equals(normalized) || "percent".equals(normalized)) {
            return "PERCENTAGE";
        }

        return normalized.replace(' ', '_').toUpperCase(Locale.ROOT);
    }

    private double normalizeAmount(Double value) {
        return value == null ? 0D : Math.max(value, 0D);
    }

    private PricingBreakdown resolvePricingBreakdown(Double subtotal, List<OrderItemPayload> orderItems) {
        if (orderItems == null || orderItems.isEmpty()) {
            double normalizedSubtotal = roundCurrency(normalizeAmount(subtotal));
            return new PricingBreakdown(normalizedSubtotal, 0D, normalizedSubtotal);
        }

        BigDecimal regularSubtotal = BigDecimal.ZERO;
        BigDecimal discountedSubtotal = BigDecimal.ZERO;

        for (OrderItemPayload item : orderItems) {
            if (item == null || item.getProductId() == null) {
                throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Each coupon item must include a product id.");
            }

            int quantity = item.getQuantity() == null ? 0 : item.getQuantity();
            if (quantity <= 0) {
                throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Each coupon item quantity must be at least 1.");
            }

            Product product = productDao.getProductById(item.getProductId());
            if (product == null) {
                throw new ResponseStatusException(HttpStatus.NOT_FOUND, "Product not found for item " + item.getProductId() + ".");
            }

            BigDecimal unitOriginalPrice = normalizeMoney(product.getPrice());
            BigDecimal discountRate = normalizeDiscountRate(product.getDiscount());
            BigDecimal unitDiscountedPrice = calculateDiscountedUnitPrice(unitOriginalPrice, discountRate);
            BigDecimal quantityValue = BigDecimal.valueOf(quantity);

            regularSubtotal = regularSubtotal.add(unitOriginalPrice.multiply(quantityValue));
            discountedSubtotal = discountedSubtotal.add(unitDiscountedPrice.multiply(quantityValue));
        }

        regularSubtotal = scaleCurrency(regularSubtotal);
        discountedSubtotal = scaleCurrency(discountedSubtotal);
        BigDecimal productDiscountTotal = scaleCurrency(regularSubtotal.subtract(discountedSubtotal));
        return new PricingBreakdown(
                regularSubtotal.doubleValue(),
                productDiscountTotal.doubleValue(),
                discountedSubtotal.doubleValue()
        );
    }

    private BigDecimal calculateDiscountedUnitPrice(BigDecimal originalPrice, BigDecimal discountRate) {
        BigDecimal multiplier = BigDecimal.ONE.subtract(discountRate.divide(BigDecimal.valueOf(100), 6, RoundingMode.HALF_UP));
        return scaleCurrency(originalPrice.multiply(multiplier));
    }

    private BigDecimal normalizeMoney(BigDecimal value) {
        return value == null ? BigDecimal.ZERO : value.max(BigDecimal.ZERO);
    }

    private BigDecimal normalizeDiscountRate(BigDecimal value) {
        BigDecimal normalized = value == null ? BigDecimal.ZERO : value;
        if (normalized.compareTo(BigDecimal.ZERO) < 0) {
            return BigDecimal.ZERO;
        }
        if (normalized.compareTo(BigDecimal.valueOf(100)) > 0) {
            return BigDecimal.valueOf(100);
        }
        return normalized;
    }

    private BigDecimal scaleCurrency(BigDecimal value) {
        return value.setScale(2, RoundingMode.HALF_UP);
    }

    private double roundCurrency(double value) {
        return scaleCurrency(BigDecimal.valueOf(value)).doubleValue();
    }

    private record PricingBreakdown(
            double regularSubtotal,
            double productDiscountTotal,
            double subtotalAfterProductDiscount
    ) {
    }
}
