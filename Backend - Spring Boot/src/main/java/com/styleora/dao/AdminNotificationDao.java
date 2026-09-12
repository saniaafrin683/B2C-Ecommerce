package com.styleora.dao;

import com.styleora.dto.AdminNotificationItem;
import com.styleora.model.Payment;
import com.styleora.model.Product;
import com.styleora.model.ReturnRequest;
import com.styleora.model.Review;
import jakarta.persistence.EntityManager;
import jakarta.persistence.PersistenceContext;
import org.springframework.stereotype.Repository;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;

@Repository
public class AdminNotificationDao {

    private static final String REAL_ORDER_FILTER =
            "lower(coalesce(o.customer.email, o.customerEmail, '')) not like '%@styleora.test'";
    private static final String REAL_REVIEW_FILTER =
            "lower(coalesce(r.customerEmail, '')) not like '%@styleora.test'";

    @PersistenceContext
    private EntityManager entityManager;

    public List<AdminNotificationItem> getAdminNotifications() {
        List<AdminNotificationItem> notifications = new ArrayList<>();

        AdminNotificationItem newOrders = buildNewOrdersNotification();
        if (newOrders != null) {
            notifications.add(newOrders);
        }

        AdminNotificationItem pendingReviews = buildPendingReviewsNotification();
        if (pendingReviews != null) {
            notifications.add(pendingReviews);
        }

        AdminNotificationItem pendingReturns = buildPendingReturnsNotification();
        if (pendingReturns != null) {
            notifications.add(pendingReturns);
        }

        AdminNotificationItem lowStock = buildLowStockNotification();
        if (lowStock != null) {
            notifications.add(lowStock);
        }

        AdminNotificationItem pendingPayments = buildPendingPaymentsNotification();
        if (pendingPayments != null) {
            notifications.add(pendingPayments);
        }

        notifications.sort(Comparator.comparing(
                AdminNotificationItem::getCreatedAt,
                Comparator.nullsLast(Comparator.reverseOrder())
        ));
        return notifications;
    }

    private AdminNotificationItem buildNewOrdersNotification() {
        LocalDate startDate = LocalDate.now().minusDays(6);
        Long count = toLong(entityManager.createQuery(
                        "select count(o) from Order o where " + REAL_ORDER_FILTER + " and o.createdAt >= :startDate"
                )
                .setParameter("startDate", startDate)
                .getSingleResult());

        if (count <= 0) {
            return null;
        }

        LocalDate latestOrderDate = entityManager.createQuery(
                        "select max(o.createdAt) from Order o where " + REAL_ORDER_FILTER + " and o.createdAt >= :startDate",
                        LocalDate.class
                )
                .setParameter("startDate", startDate)
                .getSingleResult();

        return new AdminNotificationItem(
                "orders-recent",
                "order",
                "New Orders",
                count + " recent order" + (count == 1 ? "" : "s") + " placed in the last 7 days.",
                "/orders/list",
                latestOrderDate != null ? latestOrderDate.atStartOfDay() : null
        );
    }

    private AdminNotificationItem buildPendingReviewsNotification() {
        List<Review> reviews = entityManager.createQuery(
                        "from Review r where " + REAL_REVIEW_FILTER + " and lower(coalesce(r.reviewStatus, 'pending')) like '%pending%' " +
                                "order by case when r.reviewDate is null then 1 else 0 end, r.reviewDate desc, r.id desc",
                        Review.class
                )
                .setMaxResults(25)
                .getResultList();

        if (reviews.isEmpty()) {
            return null;
        }

        Review latestReview = reviews.get(0);
        return new AdminNotificationItem(
                "reviews-pending",
                "review",
                "Pending Reviews",
                reviews.size() + " review" + (reviews.size() == 1 ? "" : "s") + " waiting for moderation.",
                "/reviews/list",
                latestReview.getReviewDate() != null ? latestReview.getReviewDate().atStartOfDay() : null
        );
    }

    private AdminNotificationItem buildPendingReturnsNotification() {
        List<ReturnRequest> requests = entityManager.createQuery(
                        "from ReturnRequest rr where lower(coalesce(rr.status, 'pending')) like '%pending%' order by rr.requestedAt desc, rr.id desc",
                        ReturnRequest.class
                )
                .setMaxResults(25)
                .getResultList();

        if (requests.isEmpty()) {
            return null;
        }

        ReturnRequest latestRequest = requests.get(0);
        return new AdminNotificationItem(
                "returns-pending",
                "return",
                "Pending Returns",
                requests.size() + " return request" + (requests.size() == 1 ? "" : "s") + " awaiting review.",
                "/returns/list",
                latestRequest.getRequestedAt()
        );
    }

    private AdminNotificationItem buildLowStockNotification() {
        List<Product> products = entityManager.createQuery(
                        "select p from Product p where coalesce(p.stock, 0) < 10 order by p.stock asc, p.updatedAt desc, p.id desc",
                        Product.class
                )
                .setMaxResults(25)
                .getResultList();

        if (products.isEmpty()) {
            return null;
        }

        Product lowestStock = products.get(0);
        String productName = lowestStock.getName() == null || lowestStock.getName().trim().isEmpty()
                ? "A product"
                : lowestStock.getName().trim();
        return new AdminNotificationItem(
                "inventory-low-stock",
                "inventory",
                "Low Stock Products",
                products.size() + " product" + (products.size() == 1 ? "" : "s") + " low in stock. " +
                        productName + " currently has " + Math.max(lowestStock.getStock() == null ? 0 : lowestStock.getStock(), 0) + " unit(s).",
                "/inventory/warehouse",
                lowestStock.getUpdatedAt()
        );
    }

    private AdminNotificationItem buildPendingPaymentsNotification() {
        List<Payment> payments = entityManager.createQuery(
                        "from Payment p where lower(coalesce(p.paymentStatus, '')) like '%pending%' order by p.paymentDate desc, p.id desc",
                        Payment.class
                )
                .setMaxResults(25)
                .getResultList();

        if (payments.isEmpty()) {
            return null;
        }

        Payment latestPayment = payments.get(0);
        return new AdminNotificationItem(
                "payments-pending",
                "payment",
                "Pending Payments",
                payments.size() + " payment" + (payments.size() == 1 ? "" : "s") + " still marked pending.",
                "/payments/list",
                latestPayment.getPaymentDate() != null ? latestPayment.getPaymentDate().atStartOfDay() : null
        );
    }

    private Long toLong(Object value) {
        return value == null ? 0L : ((Number) value).longValue();
    }
}
