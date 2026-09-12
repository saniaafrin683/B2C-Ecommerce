package com.example.myshop.model;

public class ReturnRequestCreateRequest {
    private Long orderId;
    private Long productId;
    private String reason;
    private String note;

    public ReturnRequestCreateRequest(Long orderId, Long productId, String reason, String note) {
        this.orderId = orderId;
        this.productId = productId;
        this.reason = reason;
        this.note = note;
    }
}
