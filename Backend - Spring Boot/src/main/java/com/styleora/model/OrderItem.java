package com.styleora.model;

import com.fasterxml.jackson.annotation.JsonIgnore;
import jakarta.persistence.*;

@Entity
@Table(name = "order_items")
public class OrderItem {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "order_id")
    @JsonIgnore
    private Order order;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "product_id")
    private Product product;

    @Transient
    private Long orderId;

    @Transient
    private Long productId;

    private String productName;

    @Column(columnDefinition = "LONGTEXT")
    private String productImage;

    private String size;
    private String color;
    private Double originalUnitPrice;
    private Double discountedUnitPrice;
    private Double productDiscountRate;
    private Double productDiscountAmount;
    private Double originalLineTotal;
    private Double productDiscountLineTotal;
    private Double unitPrice;
    private Integer quantity;
    private Double lineTotal;

    public OrderItem() {
    }

    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public Long getOrderId() {
        return order != null ? order.getId() : orderId;
    }

    public void setOrderId(Long orderId) {
        this.orderId = orderId;
    }

    public Order getOrder() {
        return order;
    }

    public void setOrder(Order order) {
        this.order = order;
        this.orderId = order != null ? order.getId() : null;
    }

    public Product getProduct() {
        return product;
    }

    public void setProduct(Product product) {
        this.product = product;
        this.productId = product != null ? product.getId() : null;
    }

    public Long getProductId() {
        return product != null ? product.getId() : productId;
    }

    public void setProductId(Long productId) {
        this.productId = productId;
    }

    public String getProductName() {
        return productName;
    }

    public void setProductName(String productName) {
        this.productName = productName;
    }

    public String getProductImage() {
        return productImage;
    }

    public void setProductImage(String productImage) {
        this.productImage = productImage;
    }

    public String getSize() {
        return size;
    }

    public void setSize(String size) {
        this.size = size;
    }

    public String getColor() {
        return color;
    }

    public void setColor(String color) {
        this.color = color;
    }

    public Double getOriginalUnitPrice() {
        return originalUnitPrice;
    }

    public void setOriginalUnitPrice(Double originalUnitPrice) {
        this.originalUnitPrice = originalUnitPrice;
    }

    public Double getDiscountedUnitPrice() {
        return discountedUnitPrice;
    }

    public void setDiscountedUnitPrice(Double discountedUnitPrice) {
        this.discountedUnitPrice = discountedUnitPrice;
    }

    public Double getProductDiscountRate() {
        return productDiscountRate;
    }

    public void setProductDiscountRate(Double productDiscountRate) {
        this.productDiscountRate = productDiscountRate;
    }

    public Double getProductDiscountAmount() {
        return productDiscountAmount;
    }

    public void setProductDiscountAmount(Double productDiscountAmount) {
        this.productDiscountAmount = productDiscountAmount;
    }

    public Double getOriginalLineTotal() {
        return originalLineTotal;
    }

    public void setOriginalLineTotal(Double originalLineTotal) {
        this.originalLineTotal = originalLineTotal;
    }

    public Double getProductDiscountLineTotal() {
        return productDiscountLineTotal;
    }

    public void setProductDiscountLineTotal(Double productDiscountLineTotal) {
        this.productDiscountLineTotal = productDiscountLineTotal;
    }

    public Double getUnitPrice() {
        return unitPrice;
    }

    public void setUnitPrice(Double unitPrice) {
        this.unitPrice = unitPrice;
    }

    public Integer getQuantity() {
        return quantity;
    }

    public void setQuantity(Integer quantity) {
        this.quantity = quantity;
    }

    public Double getLineTotal() {
        return lineTotal;
    }

    public void setLineTotal(Double lineTotal) {
        this.lineTotal = lineTotal;
    }
}
