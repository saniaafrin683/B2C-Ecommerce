package com.styleora.dao;

import com.styleora.model.Order;
import jakarta.persistence.EntityManager;
import jakarta.persistence.PersistenceContext;
import jakarta.transaction.Transactional;
import org.springframework.stereotype.Repository;

import java.time.LocalDate;
import java.util.List;
import java.util.Map;
import java.util.LinkedHashMap;

@Repository
@Transactional
public class OrderDao {

    private static final String ANALYTICS_REAL_ORDER_FILTER =
            "lower(coalesce(o.customer.email, o.customerEmail, '')) not like '%@styleora.test' " +
            "and lower(coalesce(o.customer.email, o.customerEmail, '')) <> 'customer@styleora.com'";

    @PersistenceContext
    private EntityManager entityManager;

    public Order saveOrder(Order order) {
        entityManager.persist(order);
        entityManager.flush();
        return order;
    }

    public List<Order> getAllOrders() {
        return entityManager
                .createQuery(
                        "select o from Order o " +
                                "order by case when o.createdAt is null then 1 else 0 end, o.createdAt desc, o.id desc",
                        Order.class
                )
                .getResultList();
    }

    public Order getOrderById(Long id) {
        return entityManager.find(Order.class, id);
    }

    public Order getOrderByIdFresh(Long id) {
        Order order = entityManager.find(Order.class, id);
        if (order != null) {
            entityManager.refresh(order);
        }
        return order;
    }

    public List<Order> getOrdersByCustomerEmail(String customerEmail) {
        return entityManager.createQuery(
                "select o from Order o where lower(coalesce(o.customer.email, o.customerEmail, '')) = lower(:customerEmail) " +
                        "order by case when o.createdAt is null then 1 else 0 end, o.createdAt desc, o.id desc",
                Order.class
        ).setParameter("customerEmail", customerEmail)
         .getResultList();
    }

    public Order getOrderByIdAndCustomerEmail(Long id, String customerEmail) {
        List<Order> results = entityManager.createQuery(
                "select o from Order o where o.id = :id and lower(coalesce(o.customer.email, o.customerEmail, '')) = lower(:customerEmail)",
                Order.class
        ).setParameter("id", id)
         .setParameter("customerEmail", customerEmail)
         .setMaxResults(1)
         .getResultList();

        return results.isEmpty() ? null : results.get(0);
    }

    public Order getOrderByOrderIdAndCustomerEmail(String orderId, String customerEmail) {
        List<Order> results = entityManager.createQuery(
                "select o from Order o where lower(coalesce(o.orderId, '')) = lower(:orderId) " +
                        "and lower(coalesce(o.customer.email, o.customerEmail, '')) = lower(:customerEmail)",
                Order.class
        ).setParameter("orderId", orderId)
         .setParameter("customerEmail", customerEmail)
         .setMaxResults(1)
         .getResultList();

        return results.isEmpty() ? null : results.get(0);
    }

    public Order updateOrder(Order order) {
        if (order.getId() == null) {
            return entityManager.merge(order);
        }

        Order existingOrder = entityManager.find(Order.class, order.getId());
        if (existingOrder == null) {
            return entityManager.merge(order);
        }

        existingOrder.setOrderId(order.getOrderId());
        existingOrder.setCreatedAt(order.getCreatedAt());
        existingOrder.setCustomer(order.getCustomer());
        existingOrder.setCustomerName(order.getCustomerName());
        existingOrder.setCustomerEmail(order.getCustomerEmail());
        existingOrder.setCustomerPhone(order.getCustomerPhone());
        existingOrder.setShippingAddress(order.getShippingAddress());
        existingOrder.setBillingAddress(order.getBillingAddress());
        existingOrder.setPriority(order.getPriority());
        existingOrder.setSubtotal(order.getSubtotal());
        existingOrder.setRegularSubtotal(order.getRegularSubtotal());
        existingOrder.setProductDiscountTotal(order.getProductDiscountTotal());
        existingOrder.setSubtotalAfterProductDiscount(order.getSubtotalAfterProductDiscount());
        existingOrder.setTax(order.getTax());
        existingOrder.setDiscount(order.getDiscount());
        existingOrder.setCouponDiscount(order.getCouponDiscount());
        existingOrder.setShippingCost(order.getShippingCost());
        existingOrder.setCouponCode(order.getCouponCode());
        existingOrder.setTotalAmount(order.getTotalAmount());
        existingOrder.setPaymentMethod(order.getPaymentMethod());
        existingOrder.setPaymentStatus(order.getPaymentStatus());
        existingOrder.setDeliveryNumber(order.getDeliveryNumber());
        existingOrder.setTrackingNumber(order.getTrackingNumber());
        existingOrder.setOrderStatus(order.getOrderStatus());
        entityManager.flush();
        return existingOrder;
    }

    public Order updateOrderStatus(Long id, String orderStatus) {
        Order existingOrder = entityManager.find(Order.class, id);
        if (existingOrder == null) {
            return null;
        }

        existingOrder.setOrderStatus(orderStatus);
        entityManager.flush();
        return existingOrder;
    }

    public Order updateOrderPaymentSnapshot(Long id, String paymentMethod, String paymentStatus) {
        Order existingOrder = entityManager.find(Order.class, id);
        if (existingOrder == null) {
            return null;
        }

        existingOrder.setPaymentMethod(paymentMethod);
        existingOrder.setPaymentStatus(paymentStatus);
        entityManager.flush();
        return existingOrder;
    }

    public void deleteOrder(Long id) {
        Order order = entityManager.find(Order.class, id);
        if (order != null) {
            entityManager.remove(order);
            entityManager.flush();
        }
    }

    public void clearPersistenceContext() {
        entityManager.clear();
    }

    public long getOrderCount() {
        Long count = entityManager.createQuery("select count(o) from Order o", Long.class)
                .getSingleResult();
        return count == null ? 0L : count;
    }

    public Long countOrders(LocalDate startDate) {
        return toLong(entityManager.createQuery(
                "select count(o) from Order o where " + ANALYTICS_REAL_ORDER_FILTER + " " +
                        "and (:startDate is null or o.createdAt >= :startDate)"
        ).setParameter("startDate", startDate).getSingleResult());
    }

    public Double getTotalRevenue(LocalDate startDate) {
        return toDouble(entityManager.createQuery(
                "select coalesce(sum(coalesce(o.totalAmount, 0)), 0) from Order o where " + ANALYTICS_REAL_ORDER_FILTER + " " +
                        "and (:startDate is null or o.createdAt >= :startDate)"
        ).setParameter("startDate", startDate).getSingleResult());
    }

    public Long countPendingOrders(LocalDate startDate) {
        return toLong(entityManager.createQuery(
                "select count(o) from Order o " +
                        "where " + ANALYTICS_REAL_ORDER_FILTER + " " +
                        "and lower(coalesce(o.orderStatus, '')) like '%pending%' " +
                        "and (:startDate is null or o.createdAt >= :startDate)"
        ).setParameter("startDate", startDate).getSingleResult());
    }

    public List<Map<String, Object>> getTopCustomers(LocalDate startDate, int limit) {
        List<Object[]> rows = entityManager.createQuery(
                "select coalesce(o.customer.fullName, o.customerName), count(o), coalesce(sum(coalesce(o.totalAmount, 0)), 0) " +
                        "from Order o " +
                        "where coalesce(o.customer.fullName, o.customerName) is not null and trim(coalesce(o.customer.fullName, o.customerName)) <> '' " +
                        "and " + ANALYTICS_REAL_ORDER_FILTER + " " +
                        "and (:startDate is null or o.createdAt >= :startDate) " +
                        "group by coalesce(o.customer.fullName, o.customerName) " +
                        "order by count(o) desc, coalesce(o.customer.fullName, o.customerName) asc",
                Object[].class
        ).setParameter("startDate", startDate)
         .setMaxResults(limit)
         .getResultList();

        return rows.stream().map((row) -> {
            Map<String, Object> item = new LinkedHashMap<>();
            item.put("customerName", row[0]);
            item.put("totalOrders", toLong(row[1]));
            item.put("totalSpend", toDouble(row[2]));
            return item;
        }).toList();
    }

    private Long toLong(Object value) {
        return value == null ? 0L : ((Number) value).longValue();
    }

    private Double toDouble(Object value) {
        return value == null ? 0D : ((Number) value).doubleValue();
    }
}
