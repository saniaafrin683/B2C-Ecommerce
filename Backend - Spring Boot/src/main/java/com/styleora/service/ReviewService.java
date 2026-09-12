package com.styleora.service;

import com.styleora.dao.CustomerDao;
import com.styleora.dao.OrderDao;
import com.styleora.dao.OrderItemDao;
import com.styleora.dao.ReviewDao;
import com.styleora.dto.ReviewSubmitRequest;
import com.styleora.model.Customer;
import com.styleora.model.Order;
import com.styleora.model.OrderItem;
import com.styleora.model.Review;
import com.styleora.security.AuthenticatedUser;
import org.springframework.stereotype.Service;
import org.springframework.http.HttpStatus;
import org.springframework.web.server.ResponseStatusException;

import java.time.LocalDate;
import java.util.List;
import java.util.Locale;

@Service
public class ReviewService {

    private final ReviewDao reviewDao;
    private final OrderDao orderDao;
    private final OrderItemDao orderItemDao;
    private final CustomerDao customerDao;

    public ReviewService(ReviewDao reviewDao, OrderDao orderDao, OrderItemDao orderItemDao, CustomerDao customerDao) {
        this.reviewDao = reviewDao;
        this.orderDao = orderDao;
        this.orderItemDao = orderItemDao;
        this.customerDao = customerDao;
    }

    public Review createReview(Review review) {
        LocalDate today = LocalDate.now();
        if (review.getReviewDate() == null) {
            review.setReviewDate(today);
        }
        if (review.getCreatedAt() == null) {
            review.setCreatedAt(today);
        }
        if (review.getReviewStatus() == null || review.getReviewStatus().trim().isEmpty()) {
            review.setReviewStatus("Pending");
        }
        review.setUpdatedAt(today);
        return reviewDao.saveReview(review);
    }

    public List<Review> getAllReviews() {
        return reviewDao.getAllReviews();
    }

    public List<Review> getApprovedReviews(int limit) {
        return reviewDao.getApprovedReviews(limit);
    }

    public List<Review> getApprovedReviewsByProductId(Long productId, int limit) {
        return reviewDao.getApprovedReviewsByProductId(productId, limit);
    }

    public List<Review> getCustomerReviewsForOrder(Long orderId, AuthenticatedUser authenticatedUser) {
        Customer customer = requireCustomerRecord(authenticatedUser);
        requireDeliveredCustomerOrder(orderId, customer.getEmail());
        return reviewDao.getReviewsByCustomerAndOrder(customer.getId(), orderId);
    }

    public List<Review> getCustomerReviews(AuthenticatedUser authenticatedUser) {
        Customer customer = requireCustomerRecord(authenticatedUser);
        return reviewDao.getReviewsByCustomer(customer.getId());
    }

    public Review submitReview(ReviewSubmitRequest request, AuthenticatedUser authenticatedUser) {
        Customer customer = requireCustomerRecord(authenticatedUser);

        if (request == null || request.getOrderId() == null) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Order id is required.");
        }
        if (request.getProductId() == null) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Product id is required.");
        }
        if (request.getRating() == null || request.getRating() < 1 || request.getRating() > 5) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Rating must be between 1 and 5.");
        }

        String comment = request.getComment() == null ? "" : request.getComment().trim();
        if (comment.isEmpty()) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Review comment is required.");
        }

        Order order = requireDeliveredCustomerOrder(request.getOrderId(), customer.getEmail());
        OrderItem orderItem = requireOrderItem(order.getId(), request.getProductId());

        if (reviewDao.existsByCustomerOrderAndProduct(customer.getId(), order.getId(), request.getProductId())) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "You have already reviewed this product for the selected order.");
        }

        Review review = new Review();
        review.setReviewCode(generateReviewCode(order.getId(), request.getProductId(), customer.getId()));
        review.setOrderId(order.getId());
        review.setProductId(request.getProductId());
        review.setProductName(resolveProductName(orderItem));
        review.setCustomerId(customer.getId());
        review.setCustomerName(customer.getFullName());
        review.setCustomerEmail(customer.getEmail());
        review.setRating(request.getRating());
        review.setReviewTitle("Review for " + resolveProductName(orderItem));
        review.setReviewMessage(comment);
        review.setReviewStatus("Pending");
        review.setReplyMessage(null);
        return createReview(review);
    }

    public Review getReviewById(Long id) {
        return reviewDao.getReviewById(id);
    }

    public Review updateReview(Long id, Review review) {
        Review existingReview = reviewDao.getReviewById(id);
        if (existingReview == null) {
            return null;
        }

        review.setCreatedAt(existingReview.getCreatedAt());
        review.setUpdatedAt(LocalDate.now());
        return reviewDao.updateReview(id, review);
    }

    public Review approveReview(Long id) {
        Review existingReview = reviewDao.getReviewById(id);
        if (existingReview == null) {
            return null;
        }

        existingReview.setUpdatedAt(LocalDate.now());
        reviewDao.updateReview(id, existingReview);
        return reviewDao.approveReview(id);
    }

    public Review rejectReview(Long id) {
        Review existingReview = reviewDao.getReviewById(id);
        if (existingReview == null) {
            return null;
        }

        existingReview.setUpdatedAt(LocalDate.now());
        reviewDao.updateReview(id, existingReview);
        return reviewDao.rejectReview(id);
    }

    public boolean deleteReview(Long id) {
        return reviewDao.deleteReview(id);
    }

    public int cleanupSeededReviews() {
        return reviewDao.deleteSeededReviews();
    }

    private Customer requireCustomerRecord(AuthenticatedUser authenticatedUser) {
        if (authenticatedUser == null || !authenticatedUser.hasRole("CUSTOMER")) {
            throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Customer authentication is required.");
        }

        Customer customer = customerDao.getCustomerById(authenticatedUser.getId());
        if (customer == null) {
            throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Customer account not found.");
        }

        return customer;
    }

    private Order requireDeliveredCustomerOrder(Long orderId, String customerEmail) {
        Order order = orderDao.getOrderByIdAndCustomerEmail(orderId, customerEmail);
        if (order == null) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "Order not found.");
        }

        if (!"delivered".equalsIgnoreCase(normalize(order.getOrderStatus()))) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Reviews can only be submitted after the order is delivered.");
        }

        return order;
    }

    private OrderItem requireOrderItem(Long orderId, Long productId) {
        return orderItemDao.getOrderItemsByOrderId(orderId).stream()
                .filter(item -> productId.equals(item.getProductId()) || (item.getProduct() != null && productId.equals(item.getProduct().getId())))
                .findFirst()
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.BAD_REQUEST, "The selected product does not belong to this order."));
    }

    private String resolveProductName(OrderItem orderItem) {
        if (orderItem.getProductName() != null && !orderItem.getProductName().trim().isEmpty()) {
            return orderItem.getProductName().trim();
        }
        if (orderItem.getProduct() != null && orderItem.getProduct().getName() != null && !orderItem.getProduct().getName().trim().isEmpty()) {
            return orderItem.getProduct().getName().trim();
        }
        return "Ordered product";
    }

    private String generateReviewCode(Long orderId, Long productId, Long customerId) {
        return String.format(Locale.ROOT, "REV-%d-%d-%d", orderId, productId, customerId);
    }

    private String normalize(String value) {
        return value == null ? "" : value.trim().toLowerCase(Locale.ROOT);
    }
}
