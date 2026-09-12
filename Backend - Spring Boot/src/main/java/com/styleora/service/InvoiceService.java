package com.styleora.service;

import com.styleora.dao.InvoiceDao;
import com.styleora.model.Invoice;
import com.styleora.model.Order;
import jakarta.transaction.Transactional;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;

import java.time.LocalDate;
import java.util.List;

@Service
public class InvoiceService {

    private static final Logger LOGGER = LoggerFactory.getLogger(InvoiceService.class);

    private final InvoiceDao invoiceDao;

    public InvoiceService(InvoiceDao invoiceDao) {
        this.invoiceDao = invoiceDao;
    }

    public Invoice createInvoice(Invoice invoice) {
        if (invoice.getIssueDate() == null) {
            invoice.setIssueDate(LocalDate.now());
        }
        if (invoice.getDueDate() == null) {
            invoice.setDueDate(invoice.getIssueDate());
        }
        return invoiceDao.saveInvoice(invoice);
    }

    public List<Invoice> getAllInvoices() {
        return invoiceDao.getAllInvoices();
    }

    public Invoice getInvoiceById(Long id) {
        return invoiceDao.getInvoiceById(id);
    }

    public List<Invoice> getInvoicesByOrderId(Long orderId) {
        return invoiceDao.getInvoicesByOrderId(orderId);
    }

    public Invoice updateInvoice(Long id, Invoice invoice) {
        return invoiceDao.updateInvoice(id, invoice);
    }

    @Transactional
    public boolean deleteInvoice(Long id) {
        LOGGER.info("Delete invoice request received for id={}", id);
        boolean deleted = invoiceDao.deleteInvoice(id);
        LOGGER.info("Delete invoice request completed for id={}, deleted={}", id, deleted);
        return deleted;
    }

    public Invoice createInvoiceForOrder(Order order) {
        if (order == null || order.getId() == null) {
            return null;
        }

        Invoice existingInvoice = invoiceDao.getLatestInvoiceByOrderId(order.getId());
        if (existingInvoice != null) {
            LOGGER.info("Invoice already exists for orderId={}, invoiceNumber={}", order.getId(), existingInvoice.getInvoiceNumber());
            return existingInvoice;
        }

        Invoice invoice = new Invoice();
        invoice.setInvoiceNumber(generateInvoiceNumber(order));
        invoice.setOrderId(order.getId());
        invoice.setOrderReference(order.getOrderId());
        invoice.setCustomerName(order.getCustomerName());
        invoice.setCustomerEmail(order.getCustomerEmail());
        invoice.setCustomerPhone(order.getCustomerPhone());
        invoice.setBillingAddress(resolveBillingAddress(order));
        invoice.setSubtotal(normalizeAmount(order.getSubtotal()));
        invoice.setRegularSubtotal(normalizeAmount(order.getRegularSubtotal()));
        invoice.setProductDiscountTotal(normalizeAmount(order.getProductDiscountTotal()));
        invoice.setSubtotalAfterProductDiscount(normalizeAmount(order.getSubtotalAfterProductDiscount()));
        invoice.setTax(normalizeAmount(order.getTax()));
        invoice.setDiscount(normalizeAmount(order.getCouponDiscount() != null ? order.getCouponDiscount() : order.getDiscount()));
        invoice.setCouponDiscount(normalizeAmount(order.getCouponDiscount() != null ? order.getCouponDiscount() : order.getDiscount()));
        invoice.setCouponCode(order.getCouponCode());
        invoice.setShippingCost(normalizeAmount(order.getShippingCost()));
        invoice.setTotalAmount(normalizeAmount(order.getTotalAmount()));
        invoice.setPaymentStatus(normalizeString(order.getPaymentStatus(), "Pending"));
        invoice.setPaymentMethod(normalizeString(order.getPaymentMethod(), "Not Set"));
        invoice.setIssueDate(order.getCreatedAt() != null ? order.getCreatedAt() : LocalDate.now());
        invoice.setDueDate(invoice.getIssueDate());
        invoice.setNotes(buildInvoiceNotes(order));
        LOGGER.info(
                "Creating invoice for orderId={}, orderReference={}, couponCode={}, couponDiscount={}, totalAmount={}",
                order.getId(),
                order.getOrderId(),
                order.getCouponCode(),
                order.getCouponDiscount(),
                order.getTotalAmount()
        );
        Invoice savedInvoice = createInvoice(invoice);
        LOGGER.info(
                "Saved invoice id={}, invoiceNumber={}, orderId={}, couponCode={}, couponDiscount={}, totalAmount={}",
                savedInvoice.getId(),
                savedInvoice.getInvoiceNumber(),
                savedInvoice.getOrderId(),
                savedInvoice.getCouponCode(),
                savedInvoice.getCouponDiscount(),
                savedInvoice.getTotalAmount()
        );
        return savedInvoice;
    }

    private String generateInvoiceNumber(Order order) {
        String orderReference = order.getOrderId() == null ? "" : order.getOrderId().trim();
        String safeReference = orderReference.replaceAll("[^A-Za-z0-9]", "");
        if (!safeReference.isEmpty()) {
            return "INV-" + safeReference;
        }

        return "INV-" + order.getId();
    }

    private String resolveBillingAddress(Order order) {
        String billingAddress = normalizeString(order.getBillingAddress(), "");
        if (!billingAddress.isEmpty()) {
            return billingAddress;
        }

        return normalizeString(order.getShippingAddress(), "");
    }

    private String buildInvoiceNotes(Order order) {
        String orderReference = normalizeString(order.getOrderId(), String.valueOf(order.getId()));
        String couponCode = normalizeString(order.getCouponCode(), "");
        if (!couponCode.isEmpty()) {
            return "Auto-generated from customer order " + orderReference + " using coupon " + couponCode;
        }

        return "Auto-generated from customer order " + orderReference;
    }

    private Double normalizeAmount(Double value) {
        return value == null ? 0D : value;
    }

    private String normalizeString(String value, String fallback) {
        String resolvedValue = value != null && !value.trim().isEmpty() ? value.trim() : fallback;
        return resolvedValue == null ? "" : resolvedValue.trim();
    }
}
