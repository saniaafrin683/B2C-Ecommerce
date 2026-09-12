package com.example.myshop.model;

public class ReviewSubmitRequest {
    private Long orderId;
    private Long productId;
    private Integer rating;
    private String comment;

    public ReviewSubmitRequest(Long orderId, Long productId, Integer rating, String comment) {
        this.orderId = orderId;
        this.productId = productId;
        this.rating = rating;
        this.comment = comment;
    }
}
