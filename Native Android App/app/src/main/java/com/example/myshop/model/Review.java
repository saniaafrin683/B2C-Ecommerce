package com.example.myshop.model;

public class Review {
    private Long id;
    private Long productId;
    private String productName;
    private Long orderId;
    private Long customerId;
    private String customerName;
    private String customerEmail;
    private Integer rating;
    private String reviewTitle;
    private String reviewMessage;
    private String reviewStatus;
    private String reviewDate;
    private String createdAt;

    public Long getId() {
        return id;
    }

    public Long getProductId() {
        return productId;
    }

    public String getProductName() {
        return productName;
    }

    public Long getOrderId() {
        return orderId;
    }

    public Long getCustomerId() {
        return customerId;
    }

    public String getCustomerName() {
        return customerName;
    }

    public String getCustomerEmail() {
        return customerEmail;
    }

    public Integer getRating() {
        return rating;
    }

    public String getReviewTitle() {
        return reviewTitle;
    }

    public String getReviewMessage() {
        return reviewMessage;
    }

    public String getReviewStatus() {
        return reviewStatus;
    }

    public String getReviewDate() {
        return reviewDate;
    }

    public String getCreatedAt() {
        return createdAt;
    }
}
