package com.styleora.service;

import com.styleora.dao.InvoiceDao;
import com.styleora.dao.PaymentDao;
import com.styleora.model.Invoice;
import com.styleora.model.Payment;
import jakarta.transaction.Transactional;
import org.springframework.stereotype.Service;

@Service
public class OrderStatusSideEffectService {

    private final InvoiceDao invoiceDao;
    private final PaymentDao paymentDao;

    public OrderStatusSideEffectService(InvoiceDao invoiceDao, PaymentDao paymentDao) {
        this.invoiceDao = invoiceDao;
        this.paymentDao = paymentDao;
    }

    @Transactional(Transactional.TxType.REQUIRES_NEW)
    public void syncPaymentSnapshotsForStatusChange(Long orderId, String paymentMethod, String orderStatus) {
        if (orderId == null) {
            return;
        }

        String normalizedPaymentMethod = normalizeString(paymentMethod);
        String nextPaymentStatus = resolvePaymentStatusForOrderStatus(orderStatus);
        Invoice latestInvoice = invoiceDao.getLatestInvoiceByOrderId(orderId);
        if (latestInvoice != null) {
            invoiceDao.updateInvoicePaymentSnapshot(latestInvoice.getId(), normalizedPaymentMethod, nextPaymentStatus);
        }

        Payment latestPayment = paymentDao.getLatestPaymentByOrderId(orderId);
        if (latestPayment != null) {
            paymentDao.updatePaymentSnapshot(latestPayment.getId(), normalizedPaymentMethod, nextPaymentStatus);
        }
    }

    public String resolvePaymentStatusForOrderStatus(String orderStatus) {
        String normalizedOrderStatus = normalizeString(orderStatus).toLowerCase();
        return switch (normalizedOrderStatus) {
            case "delivered" -> "Paid";
            case "cancelled" -> "Cancelled";
            case "pending", "confirmed", "processing", "shipped" -> "Pending";
            default -> "Pending";
        };
    }

    private String normalizeString(String value) {
        return value == null ? "" : value.trim();
    }
}
