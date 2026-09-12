package com.styleora.dao;

import com.styleora.model.OrderItem;
import jakarta.persistence.EntityManager;
import jakarta.persistence.PersistenceContext;
import jakarta.transaction.Transactional;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
@Transactional
public class OrderItemDao {

    @PersistenceContext
    private EntityManager entityManager;

    public void saveOrderItem(OrderItem orderItem) {
        entityManager.persist(orderItem);
    }

    public List<OrderItem> getOrderItemsByOrderId(Long orderId) {
        return entityManager.createQuery(
                "from OrderItem oi where oi.order.id = :orderId order by oi.id",
                OrderItem.class
        ).setParameter("orderId", orderId).getResultList();
    }

    public void deleteOrderItemsByOrderId(Long orderId) {
        entityManager.createQuery("delete from OrderItem oi where oi.order.id = :orderId")
                .setParameter("orderId", orderId)
                .executeUpdate();
    }
}
