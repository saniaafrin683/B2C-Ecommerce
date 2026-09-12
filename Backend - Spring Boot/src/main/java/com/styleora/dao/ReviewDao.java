package com.styleora.dao;

import com.styleora.model.Review;
import jakarta.persistence.EntityManager;
import jakarta.persistence.PersistenceContext;
import jakarta.transaction.Transactional;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
@Transactional
public class ReviewDao {

    private static final String SAMPLE_REVIEW_FILTER =
            "lower(coalesce(r.customerEmail, '')) not like '%@styleora.test'";

    @PersistenceContext
    private EntityManager entityManager;

    public Review saveReview(Review review) {
        entityManager.persist(review);
        entityManager.flush();
        return review;
    }

    public List<Review> getAllReviews() {
        return entityManager
                .createQuery("from Review r where " + SAMPLE_REVIEW_FILTER + " order by r.id desc", Review.class)
                .getResultList();
    }

    public List<Review> getApprovedReviews(int limit) {
        return entityManager
                .createQuery(
                        "from Review r where " + SAMPLE_REVIEW_FILTER + " " +
                                "and lower(coalesce(r.reviewStatus, '')) like '%approved%' " +
                                "order by case when r.reviewDate is null then 1 else 0 end, r.reviewDate desc, r.id desc",
                        Review.class
                )
                .setMaxResults(limit)
                .getResultList();
    }

    public List<Review> getApprovedReviewsByProductId(Long productId, int limit) {
        return entityManager
                .createQuery(
                        "from Review r where " + SAMPLE_REVIEW_FILTER + " " +
                                "and r.productId = :productId " +
                                "and lower(coalesce(r.reviewStatus, '')) like '%approved%' " +
                                "order by case when r.reviewDate is null then 1 else 0 end, r.reviewDate desc, r.id desc",
                        Review.class
                )
                .setParameter("productId", productId)
                .setMaxResults(limit)
                .getResultList();
    }

    public int deleteSeededReviews() {
        int deleted = entityManager.createQuery(
                        "delete from Review r where lower(coalesce(r.customerEmail, '')) like '%@styleora.test'")
                .executeUpdate();
        entityManager.flush();
        return deleted;
    }

    public Review getReviewById(Long id) {
        return entityManager.find(Review.class, id);
    }

    public Review updateReview(Long id, Review review) {
        Review existingReview = entityManager.find(Review.class, id);
        if (existingReview == null) {
            return null;
        }

        existingReview.setReviewCode(review.getReviewCode());
        existingReview.setProductId(review.getProductId());
        existingReview.setProductName(review.getProductName());
        existingReview.setOrderId(review.getOrderId());
        existingReview.setCustomerId(review.getCustomerId());
        existingReview.setCustomerName(review.getCustomerName());
        existingReview.setCustomerEmail(review.getCustomerEmail());
        existingReview.setRating(review.getRating());
        existingReview.setReviewTitle(review.getReviewTitle());
        existingReview.setReviewMessage(review.getReviewMessage());
        existingReview.setReviewStatus(review.getReviewStatus());
        existingReview.setReviewDate(review.getReviewDate());
        existingReview.setReplyMessage(review.getReplyMessage());
        existingReview.setCreatedAt(review.getCreatedAt());
        existingReview.setUpdatedAt(review.getUpdatedAt());

        return entityManager.merge(existingReview);
    }

    public boolean existsByCustomerOrderAndProduct(Long customerId, Long orderId, Long productId) {
        Long count = entityManager.createQuery(
                        "select count(r) from Review r " +
                                "where r.customerId = :customerId and r.orderId = :orderId and r.productId = :productId",
                        Long.class
                )
                .setParameter("customerId", customerId)
                .setParameter("orderId", orderId)
                .setParameter("productId", productId)
                .getSingleResult();
        return count != null && count > 0;
    }

    public List<Review> getReviewsByCustomerAndOrder(Long customerId, Long orderId) {
        return entityManager.createQuery(
                        "from Review r where r.customerId = :customerId and r.orderId = :orderId " +
                                "order by case when r.reviewDate is null then 1 else 0 end, r.reviewDate desc, r.id desc",
                        Review.class
                )
                .setParameter("customerId", customerId)
                .setParameter("orderId", orderId)
                .getResultList();
    }

    public List<Review> getReviewsByCustomer(Long customerId) {
        return entityManager.createQuery(
                        "from Review r where r.customerId = :customerId " +
                                "order by case when r.reviewDate is null then 1 else 0 end, r.reviewDate desc, r.id desc",
                        Review.class
                )
                .setParameter("customerId", customerId)
                .getResultList();
    }

    public Review approveReview(Long id) {
        Review review = entityManager.find(Review.class, id);
        if (review == null) {
            return null;
        }

        review.setReviewStatus("Approved");
        return entityManager.merge(review);
    }

    public Review rejectReview(Long id) {
        Review review = entityManager.find(Review.class, id);
        if (review == null) {
            return null;
        }

        review.setReviewStatus("Rejected");
        return entityManager.merge(review);
    }

    public boolean deleteReview(Long id) {
        Review review = entityManager.find(Review.class, id);
        if (review == null) {
            return false;
        }

        entityManager.remove(review);
        entityManager.flush();
        return true;
    }

    public int deleteReviewsByOrderId(Long orderId) {
        int deleted = entityManager.createQuery("delete from Review r where r.orderId = :orderId")
                .setParameter("orderId", orderId)
                .executeUpdate();
        entityManager.flush();
        return deleted;
    }
}
