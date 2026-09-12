package com.styleora.dto;

import com.fasterxml.jackson.annotation.JsonFormat;
import com.fasterxml.jackson.annotation.JsonProperty;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

public class OrderDetailsResponse {
    private Long id;
    private String orderId;
    @JsonFormat(pattern = "yyyy-MM-dd")
    private LocalDate createdAt;
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
    private String deliveryNumber;
    private String trackingNumber;
    private String courierName;
    private String shipmentStatus;
    @JsonFormat(pattern = "yyyy-MM-dd'T'HH:mm:ss")
    private LocalDateTime shippedDate;
    @JsonFormat(pattern = "yyyy-MM-dd'T'HH:mm:ss")
    private LocalDateTime estimatedDeliveryDate;
    @JsonFormat(pattern = "yyyy-MM-dd'T'HH:mm:ss")
    private LocalDateTime deliveredDate;
    private String orderStatus;
    private List<OrderItemPayload> orderItems = new ArrayList<>();

    public OrderDetailsResponse() {
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

    public LocalDate getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(LocalDate createdAt) {
        this.createdAt = createdAt;
    }

    public String getCustomerName() {
        return customerName;
    }

    public void setCustomerName(String customerName) {
        this.customerName = customerName;
    }

    public String getCustomerEmail() {
        return customerEmail;
    }

    public void setCustomerEmail(String customerEmail) {
        this.customerEmail = customerEmail;
    }

    public String getCustomerPhone() {
        return customerPhone;
    }

    public void setCustomerPhone(String customerPhone) {
        this.customerPhone = customerPhone;
    }

    public String getShippingAddress() {
        return shippingAddress;
    }

    public void setShippingAddress(String shippingAddress) {
        this.shippingAddress = shippingAddress;
    }

    public String getBillingAddress() {
        return billingAddress;
    }

    public void setBillingAddress(String billingAddress) {
        this.billingAddress = billingAddress;
    }

    public String getPriority() {
        return priority;
    }

    public void setPriority(String priority) {
        this.priority = priority;
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

    public Double getTax() {
        return tax;
    }

    public void setTax(Double tax) {
        this.tax = tax;
    }

    public Double getDiscount() {
        return discount;
    }

    public void setDiscount(Double discount) {
        this.discount = discount;
    }

    public Double getCouponDiscount() {
        return couponDiscount;
    }

    public void setCouponDiscount(Double couponDiscount) {
        this.couponDiscount = couponDiscount;
    }

    public Double getShippingCost() {
        return shippingCost;
    }

    public void setShippingCost(Double shippingCost) {
        this.shippingCost = shippingCost;
    }

    public String getCouponCode() {
        return couponCode;
    }

    public void setCouponCode(String couponCode) {
        this.couponCode = couponCode;
    }

    public Double getTotalAmount() {
        return totalAmount;
    }

    public void setTotalAmount(Double totalAmount) {
        this.totalAmount = totalAmount;
    }

    @JsonProperty("grandTotal")
    public Double getGrandTotal() {
        return totalAmount;
    }

    @JsonProperty("grandTotal")
    public void setGrandTotal(Double grandTotal) {
        this.totalAmount = grandTotal;
    }

    @JsonProperty("finalTotal")
    public Double getFinalTotal() {
        return totalAmount;
    }

    @JsonProperty("finalTotal")
    public void setFinalTotal(Double finalTotal) {
        this.totalAmount = finalTotal;
    }

    public String getPaymentMethod() {
        return paymentMethod;
    }

    public void setPaymentMethod(String paymentMethod) {
        this.paymentMethod = paymentMethod;
    }

    public String getPaymentStatus() {
        return paymentStatus;
    }

    public void setPaymentStatus(String paymentStatus) {
        this.paymentStatus = paymentStatus;
    }

    public Integer getItems() {
        return orderItems == null ? 0 : orderItems.size();
    }

    public void setItems(Integer items) {
    }

    public String getDeliveryNumber() {
        return deliveryNumber;
    }

    public void setDeliveryNumber(String deliveryNumber) {
        this.deliveryNumber = deliveryNumber;
    }

    public String getTrackingNumber() {
        return trackingNumber;
    }

    public void setTrackingNumber(String trackingNumber) {
        this.trackingNumber = trackingNumber;
    }

    public String getCourierName() {
        return courierName;
    }

    public void setCourierName(String courierName) {
        this.courierName = courierName;
    }

    public String getShipmentStatus() {
        return shipmentStatus;
    }

    public void setShipmentStatus(String shipmentStatus) {
        this.shipmentStatus = shipmentStatus;
    }

    public LocalDateTime getShippedDate() {
        return shippedDate;
    }

    public void setShippedDate(LocalDateTime shippedDate) {
        this.shippedDate = shippedDate;
    }

    public LocalDateTime getEstimatedDeliveryDate() {
        return estimatedDeliveryDate;
    }

    public void setEstimatedDeliveryDate(LocalDateTime estimatedDeliveryDate) {
        this.estimatedDeliveryDate = estimatedDeliveryDate;
    }

    public LocalDateTime getDeliveredDate() {
        return deliveredDate;
    }

    public void setDeliveredDate(LocalDateTime deliveredDate) {
        this.deliveredDate = deliveredDate;
    }

    public String getOrderStatus() {
        return orderStatus;
    }

    public void setOrderStatus(String orderStatus) {
        this.orderStatus = orderStatus;
    }

    public List<OrderItemPayload> getOrderItems() {
        return orderItems;
    }

    public void setOrderItems(List<OrderItemPayload> orderItems) {
        this.orderItems = orderItems;
    }
}
