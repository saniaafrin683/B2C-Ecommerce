package com.styleora.dao;

import com.styleora.model.Invoice;
import jakarta.persistence.EntityManager;
import jakarta.persistence.PersistenceContext;
import jakarta.transaction.Transactional;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
@Transactional
public class InvoiceDao {

    private static final Logger LOGGER = LoggerFactory.getLogger(InvoiceDao.class);

    @PersistenceContext
    private EntityManager entityManager;

    public Invoice saveInvoice(Invoice invoice) {
        entityManager.persist(invoice);
        entityManager.flush();
        return invoice;
    }

    public List<Invoice> getAllInvoices() {
        return entityManager
                .createQuery("from Invoice i order by i.id desc", Invoice.class)
                .getResultList();
    }

    public Invoice getInvoiceById(Long id) {
        return entityManager.find(Invoice.class, id);
    }

    public List<Invoice> getInvoicesByOrderId(Long orderId) {
        return entityManager
                .createQuery("from Invoice i where i.orderId = :orderId order by i.id desc", Invoice.class)
                .setParameter("orderId", orderId)
                .getResultList();
    }

    public Invoice updateInvoice(Long id, Invoice invoice) {
        Invoice existingInvoice = entityManager.find(Invoice.class, id);
        if (existingInvoice == null) {
            return null;
        }

        existingInvoice.setInvoiceNumber(invoice.getInvoiceNumber());
        existingInvoice.setOrderId(invoice.getOrderId());
        existingInvoice.setOrderReference(invoice.getOrderReference());
        existingInvoice.setCustomerName(invoice.getCustomerName());
        existingInvoice.setCustomerEmail(invoice.getCustomerEmail());
        existingInvoice.setCustomerPhone(invoice.getCustomerPhone());
        existingInvoice.setBillingAddress(invoice.getBillingAddress());
        existingInvoice.setSubtotal(invoice.getSubtotal());
        existingInvoice.setRegularSubtotal(invoice.getRegularSubtotal());
        existingInvoice.setProductDiscountTotal(invoice.getProductDiscountTotal());
        existingInvoice.setSubtotalAfterProductDiscount(invoice.getSubtotalAfterProductDiscount());
        existingInvoice.setTax(invoice.getTax());
        existingInvoice.setDiscount(invoice.getDiscount());
        existingInvoice.setCouponDiscount(invoice.getCouponDiscount());
        existingInvoice.setCouponCode(invoice.getCouponCode());
        existingInvoice.setShippingCost(invoice.getShippingCost());
        existingInvoice.setTotalAmount(invoice.getTotalAmount());
        existingInvoice.setPaymentStatus(invoice.getPaymentStatus());
        existingInvoice.setPaymentMethod(invoice.getPaymentMethod());
        existingInvoice.setIssueDate(invoice.getIssueDate());
        existingInvoice.setDueDate(invoice.getDueDate());
        existingInvoice.setNotes(invoice.getNotes());

        return entityManager.merge(existingInvoice);
    }

    public boolean deleteInvoice(Long id) {
        Invoice invoice = entityManager.find(Invoice.class, id);
        if (invoice == null) {
            LOGGER.info("Invoice delete skipped because no entity was found for id={}", id);
            return false;
        }

        LOGGER.info("Deleting invoice entity id={}, invoiceNumber={}", id, invoice.getInvoiceNumber());
        entityManager.remove(invoice);
        entityManager.flush();
        LOGGER.info("Invoice entity removed and flushed for id={}", id);
        return true;
    }

    public Invoice getLatestInvoiceByOrderId(Long orderId) {
        List<Invoice> results = entityManager
                .createQuery("from Invoice i where i.orderId = :orderId order by i.id desc", Invoice.class)
                .setParameter("orderId", orderId)
                .setMaxResults(1)
                .getResultList();

        return results.isEmpty() ? null : results.get(0);
    }

    public Invoice updateInvoicePaymentSnapshot(Long id, String paymentMethod, String paymentStatus) {
        Invoice existingInvoice = entityManager.find(Invoice.class, id);
        if (existingInvoice == null) {
            return null;
        }

        existingInvoice.setPaymentMethod(paymentMethod);
        existingInvoice.setPaymentStatus(paymentStatus);
        entityManager.flush();
        return existingInvoice;
    }

    public int deleteInvoicesByOrderId(Long orderId) {
        int deleted = entityManager.createQuery("delete from Invoice i where i.orderId = :orderId")
                .setParameter("orderId", orderId)
                .executeUpdate();
        entityManager.flush();
        return deleted;
    }
}
