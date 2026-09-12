package com.styleora.controller;

import com.styleora.dto.ApplyCouponRequest;
import com.styleora.dto.ApplyCouponResponse;
import com.styleora.model.Coupon;
import com.styleora.service.CouponService;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/coupons")
public class CouponController {

    private final CouponService couponService;

    public CouponController(CouponService couponService) {
        this.couponService = couponService;
    }

    @PostMapping("/create")
    public ResponseEntity<Coupon> createCoupon(@RequestBody Coupon coupon) {
        coupon.setId(null);
        return ResponseEntity.status(HttpStatus.CREATED).body(couponService.createCoupon(coupon));
    }

    @PostMapping("/apply")
    public ResponseEntity<ApplyCouponResponse> applyCoupon(@RequestBody ApplyCouponRequest request) {
        return ResponseEntity.ok(couponService.applyCoupon(request.getCouponCode(), request.getSubtotal(), request.getOrderItems()));
    }

    @GetMapping("/list")
    public List<Coupon> getAllCoupons() {
        return couponService.getAllCoupons();
    }

    @GetMapping("/{id}")
    public ResponseEntity<Coupon> getCouponById(@PathVariable Long id) {
        Coupon coupon = couponService.getCouponById(id);
        if (coupon == null) {
            return ResponseEntity.notFound().build();
        }

        return ResponseEntity.ok(coupon);
    }

    @PutMapping("/update/{id}")
    public ResponseEntity<Coupon> updateCoupon(@PathVariable Long id, @RequestBody Coupon coupon) {
        Coupon updatedCoupon = couponService.updateCoupon(id, coupon);
        if (updatedCoupon == null) {
            return ResponseEntity.notFound().build();
        }

        return ResponseEntity.ok(updatedCoupon);
    }

    @DeleteMapping("/delete/{id}")
    public ResponseEntity<Void> deleteCoupon(@PathVariable Long id) {
        boolean deleted = couponService.deleteCoupon(id);
        if (!deleted) {
            return ResponseEntity.notFound().build();
        }

        return ResponseEntity.noContent().build();
    }
}
