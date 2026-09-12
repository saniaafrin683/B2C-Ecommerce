package com.styleora.dao;

import java.util.List;

import jakarta.persistence.EntityManager;
import jakarta.persistence.LockModeType;
import jakarta.persistence.PersistenceContext;
import jakarta.transaction.Transactional;

import org.springframework.stereotype.Repository;

import com.styleora.model.ReceivedOrder;

@Repository
@Transactional
public class ReceivedOrderDao {

    @PersistenceContext
    private EntityManager entityManager;

    public ReceivedOrder saveReceivedOrder(ReceivedOrder order) {
        entityManager.persist(order);
        entityManager.flush();
        return order;
    }

    public List<ReceivedOrder> getAllReceivedOrders() {
        return entityManager
                .createQuery("from ReceivedOrder order by createdAt desc, id desc", ReceivedOrder.class)
                .getResultList();
    }

    public ReceivedOrder getReceivedOrderById(Long id) {
        return entityManager.find(ReceivedOrder.class, id);
    }

    public ReceivedOrder getReceivedOrderByIdForUpdate(Long id) {
        return entityManager.find(ReceivedOrder.class, id, LockModeType.PESSIMISTIC_WRITE);
    }

    public ReceivedOrder updateReceivedOrder(ReceivedOrder order) {
        ReceivedOrder mergedOrder = entityManager.merge(order);
        entityManager.flush();
        return mergedOrder;
    }

    public void deleteReceivedOrder(Long id) {
        ReceivedOrder order = entityManager.find(ReceivedOrder.class, id);
        if (order != null) {
            entityManager.remove(order);
        }
    }
}
