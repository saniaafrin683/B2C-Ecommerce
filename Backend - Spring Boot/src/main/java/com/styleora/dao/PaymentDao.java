package com.styleora.dao;

import com.styleora.model.Payment;
import jakarta.persistence.EntityManager;
import jakarta.persistence.PersistenceContext;
import jakarta.transaction.Transactional;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
@Transactional
public class PaymentDao {

    @PersistenceContext
    private EntityManager entityManager;

    public Payment savePayment(Payment payment) {
        entityManager.persist(payment);
        return payment;
    }

    public List<Payment> getAllPayments() {
        return entityManager
                .createQuery("from Payment p order by p.id desc", Payment.class)
                .getResultList();
    }

    public Payment getPaymentById(Long id) {
        return entityManager.find(Payment.class, id);
    }

    public List<Payment> getPaymentsByInvoiceId(Long invoiceId) {
        return entityManager
                .createQuery("from Payment p where p.invoiceId = :invoiceId order by p.id desc", Payment.class)
                .setParameter("invoiceId", invoiceId)
                .getResultList();
    }

    public List<Payment> getPaymentsByOrderId(Long orderId) {
        return entityManager
                .createQuery("from Payment p where p.orderId = :orderId order by p.id desc", Payment.class)
                .setParameter("orderId", orderId)
                .getResultList();
    }

    public Payment getLatestPaymentByOrderId(Long orderId) {
        List<Payment> results = entityManager
                .createQuery("from Payment p where p.orderId = :orderId order by p.id desc", Payment.class)
                .setParameter("orderId", orderId)
                .setMaxResults(1)
                .getResultList();

        return results.isEmpty() ? null : results.get(0);
    }

    public Payment getPaymentByTransactionId(String transactionId) {
        List<Payment> results = entityManager
                .createQuery("from Payment p where lower(coalesce(p.transactionId, '')) = lower(:transactionId)", Payment.class)
                .setParameter("transactionId", transactionId == null ? "" : transactionId)
                .setMaxResults(1)
                .getResultList();

        return results.isEmpty() ? null : results.get(0);
    }

    public int deletePaymentsByTransactionIds(List<String> transactionIds) {
        if (transactionIds == null || transactionIds.isEmpty()) {
            return 0;
        }

        int deleted = entityManager.createQuery("delete from Payment p where p.transactionId in :transactionIds")
                .setParameter("transactionIds", transactionIds)
                .executeUpdate();
        entityManager.flush();
        return deleted;
    }

    public Payment updatePayment(Long id, Payment payment) {
        Payment existingPayment = entityManager.find(Payment.class, id);
        if (existingPayment == null) {
            return null;
        }

        existingPayment.setInvoiceId(payment.getInvoiceId());
        existingPayment.setOrderId(payment.getOrderId());
        existingPayment.setCustomerName(payment.getCustomerName());
        existingPayment.setAmount(payment.getAmount());
        existingPayment.setPaymentMethod(payment.getPaymentMethod());
        existingPayment.setTransactionId(payment.getTransactionId());
        existingPayment.setPaymentStatus(payment.getPaymentStatus());
        existingPayment.setPaymentDate(payment.getPaymentDate());
        existingPayment.setNotes(payment.getNotes());
        existingPayment.setCreatedAt(payment.getCreatedAt());
        existingPayment.setUpdatedAt(payment.getUpdatedAt());

        return entityManager.merge(existingPayment);
    }

    public Payment updatePaymentSnapshot(Long id, String paymentMethod, String paymentStatus) {
        Payment existingPayment = entityManager.find(Payment.class, id);
        if (existingPayment == null) {
            return null;
        }

        existingPayment.setPaymentMethod(paymentMethod);
        existingPayment.setPaymentStatus(paymentStatus);
        entityManager.flush();
        return existingPayment;
    }

    public boolean deletePayment(Long id) {
        Payment payment = entityManager.find(Payment.class, id);
        if (payment == null) {
            return false;
        }

        entityManager.remove(payment);
        return true;
    }

    public int deletePaymentsByOrderId(Long orderId) {
        int deleted = entityManager.createQuery("delete from Payment p where p.orderId = :orderId")
                .setParameter("orderId", orderId)
                .executeUpdate();
        entityManager.flush();
        return deleted;
    }
}
