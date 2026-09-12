package com.styleora.model;

import com.fasterxml.jackson.annotation.JsonFormat;
import com.fasterxml.jackson.annotation.JsonIgnore;
import com.fasterxml.jackson.annotation.JsonProperty;
import jakarta.persistence.*;

import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;

@Entity
@Table(name = "orders")
public class Order {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "order_id")
    private String orderId;

    @Column(name = "created_at")
    @JsonFormat(pattern = "yyyy-MM-dd")
    private LocalDate createdAt;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "customer_id")
    @JsonIgnore
    private Customer customer;

    @OneToMany(mappedBy = "order", cascade = CascadeType.ALL, orphanRemoval = true)
    @JsonIgnore
    private List<OrderItem> orderItems = new ArrayList<>();

    @Column(name = "customer_name")
    private String customerName;

    @Column(name = "customer_email")
    private String customerEmail;

    @Column(name = "customer_phone")
    private String customerPhone;

    @Column(name = "shipping_address", length = 2000)
    private String shippingAddress;

    @Column(name = "billing_address", length = 2000)
    private String billingAddress;

    private String priority;

    @Column(name = "subtotal")
    private Double subtotal;

    @Column(name = "regular_subtotal")
    private Double regularSubtotal;

    @Column(name = "product_discount_total")
    private Double productDiscountTotal;

    @Column(name = "subtotal_after_product_discount")
    private Double subtotalAfterProductDiscount;

    @Column(name = "tax")
    private Double tax;

    @Column(name = "discount")
    private Double discount;

    @Column(name = "coupon_discount")
    private Double couponDiscount;

    @Column(name = "shipping_cost")
    private Double shippingCost;

    @Column(name = "coupon_code")
    private String couponCode;

    @Column(name = "total_amount")
    private Double totalAmount;

    @Column(name = "payment_method")
    private String paymentMethod;

    @Column(name = "payment_status")
    private String paymentStatus;

    @Column(name = "payment_sender_number")
    private String paymentSenderNumber;

    @Column(name = "payment_transaction_id")
    private String paymentTransactionId;

    @Column(name = "delivery_number")
    private String deliveryNumber;

    @Column(name = "tracking_number")
    private String trackingNumber;

    @Column(name = "order_status")
    private String orderStatus;

    public Order() {
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

    public Customer getCustomer() {
        return customer;
    }

    public void setCustomer(Customer customer) {
        this.customer = customer;
    }

    public List<OrderItem> getOrderItems() {
        return orderItems;
    }

    public void setOrderItems(List<OrderItem> orderItems) {
        this.orderItems = orderItems == null ? new ArrayList<>() : orderItems;
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

    @Transient
    @JsonProperty("grandTotal")
    public Double getGrandTotal() {
        return totalAmount;
    }

    @JsonProperty("grandTotal")
    public void setGrandTotal(Double grandTotal) {
        this.totalAmount = grandTotal;
    }

    @Transient
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

    public String getPaymentSenderNumber() {
        return paymentSenderNumber;
    }

    public void setPaymentSenderNumber(String paymentSenderNumber) {
        this.paymentSenderNumber = paymentSenderNumber;
    }

    public String getPaymentTransactionId() {
        return paymentTransactionId;
    }

    public void setPaymentTransactionId(String paymentTransactionId) {
        this.paymentTransactionId = paymentTransactionId;
    }

    @Transient
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

    public String getOrderStatus() {
        return orderStatus;
    }

    public void setOrderStatus(String orderStatus) {
        this.orderStatus = orderStatus;
    }
}