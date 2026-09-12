package com.styleora.controller;

import com.styleora.dto.ReviewSubmitRequest;
import com.styleora.model.Review;
import com.styleora.security.AuthenticatedUser;
import com.styleora.service.ReviewService;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/reviews")
public class ReviewController {

    private final ReviewService reviewService;

    public ReviewController(ReviewService reviewService) {
        this.reviewService = reviewService;
    }

    @PostMapping("/create")
    public ResponseEntity<Review> createReview(@RequestBody Review review) {
        review.setId(null);
        return ResponseEntity.status(HttpStatus.CREATED).body(reviewService.createReview(review));
    }

    @PostMapping("/submit")
    public ResponseEntity<Review> submitReview(
            @RequestBody ReviewSubmitRequest request,
            @AuthenticationPrincipal AuthenticatedUser authenticatedUser
    ) {
        return ResponseEntity.status(HttpStatus.CREATED).body(reviewService.submitReview(request, authenticatedUser));
    }

    @GetMapping("/list")
    public List<Review> getAllReviews() {
        return reviewService.getAllReviews();
    }

    @GetMapping("/approved")
    public List<Review> getApprovedReviews(@RequestParam(defaultValue = "6") int limit) {
        return reviewService.getApprovedReviews(Math.max(1, Math.min(limit, 20)));
    }

    @GetMapping("/my/order/{orderId}")
    public List<Review> getCustomerReviewsForOrder(
            @PathVariable Long orderId,
            @AuthenticationPrincipal AuthenticatedUser authenticatedUser
    ) {
        return reviewService.getCustomerReviewsForOrder(orderId, authenticatedUser);
    }

    @GetMapping("/my")
    public List<Review> getCustomerReviews(@AuthenticationPrincipal AuthenticatedUser authenticatedUser) {
        return reviewService.getCustomerReviews(authenticatedUser);
    }

    @GetMapping("/product/{productId}/approved")
    public List<Review> getApprovedReviewsByProduct(@PathVariable Long productId, @RequestParam(defaultValue = "6") int limit) {
        return reviewService.getApprovedReviewsByProductId(productId, Math.max(1, Math.min(limit, 20)));
    }

    @GetMapping("/{id}")
    public ResponseEntity<Review> getReviewById(@PathVariable Long id) {
        Review review = reviewService.getReviewById(id);
        if (review == null) {
            return ResponseEntity.notFound().build();
        }

        return ResponseEntity.ok(review);
    }

    @PutMapping("/update/{id}")
    public ResponseEntity<Review> updateReview(@PathVariable Long id, @RequestBody Review review) {
        Review updatedReview = reviewService.updateReview(id, review);
        if (updatedReview == null) {
            return ResponseEntity.notFound().build();
        }

        return ResponseEntity.ok(updatedReview);
    }

    @PutMapping("/approve/{id}")
    public ResponseEntity<Review> approveReview(@PathVariable Long id) {
        Review approvedReview = reviewService.approveReview(id);
        if (approvedReview == null) {
            return ResponseEntity.notFound().build();
        }

        return ResponseEntity.ok(approvedReview);
    }

    @PutMapping("/reject/{id}")
    public ResponseEntity<Review> rejectReview(@PathVariable Long id) {
        Review rejectedReview = reviewService.rejectReview(id);
        if (rejectedReview == null) {
            return ResponseEntity.notFound().build();
        }

        return ResponseEntity.ok(rejectedReview);
    }

    @DeleteMapping("/delete/{id}")
    public ResponseEntity<Void> deleteReview(@PathVariable Long id) {
        boolean deleted = reviewService.deleteReview(id);
        if (!deleted) {
            return ResponseEntity.notFound().build();
        }

        return ResponseEntity.noContent().build();
    }
}
