package com.styleora.service;

import com.styleora.dao.InvoiceDao;
import com.styleora.dao.OrderDao;
import com.styleora.dao.PaymentDao;
import com.styleora.model.Invoice;
import com.styleora.model.Order;
import com.styleora.model.Payment;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

import java.time.LocalDate;
import java.util.List;

@Service
public class PaymentService {

    private final PaymentDao paymentDao;
    private final OrderDao orderDao;
    private final InvoiceDao invoiceDao;

    public PaymentService(PaymentDao paymentDao, OrderDao orderDao, InvoiceDao invoiceDao) {
        this.paymentDao = paymentDao;
        this.orderDao = orderDao;
        this.invoiceDao = invoiceDao;
    }

    public Payment createPayment(Payment payment) {
        Payment preparedPayment = preparePaymentForSave(payment, null);
        Payment savedPayment = paymentDao.savePayment(preparedPayment);
        syncLinkedRecords(savedPayment);
        return savedPayment;
    }

    public List<Payment> getAllPayments() {
        return paymentDao.getAllPayments();
    }

    public Payment getPaymentById(Long id) {
        return paymentDao.getPaymentById(id);
    }

    public List<Payment> getPaymentsByInvoiceId(Long invoiceId) {
        return paymentDao.getPaymentsByInvoiceId(invoiceId);
    }

    public List<Payment> getPaymentsByOrderId(Long orderId) {
        return paymentDao.getPaymentsByOrderId(orderId);
    }

    public Payment updatePayment(Long id, Payment payment) {
        Payment existingPayment = paymentDao.getPaymentById(id);
        if (existingPayment == null) {
            return null;
        }

        Payment preparedPayment = preparePaymentForSave(payment, existingPayment);
        Payment updatedPayment = paymentDao.updatePayment(id, preparedPayment);
        syncLinkedRecords(updatedPayment);
        return updatedPayment;
    }

    public boolean deletePayment(Long id) {
        return paymentDao.deletePayment(id);
    }

    public Payment syncPaymentForOrder(Order order, Invoice invoice) {
        if (order == null || order.getId() == null) {
            return null;
        }

        Payment existingPayment = paymentDao.getLatestPaymentByOrderId(order.getId());
        Payment payment = existingPayment == null ? new Payment() : existingPayment;

        payment.setOrderId(order.getId());
        payment.setInvoiceId(invoice != null ? invoice.getId() : payment.getInvoiceId());
        payment.setCustomerName(normalizeText(order.getCustomerName(), "Customer"));
        payment.setAmount(normalizeAmount(order.getTotalAmount()));
        payment.setPaymentMethod(normalizePaymentMethod(order.getPaymentMethod()));
        payment.setPaymentStatus(normalizePaymentStatus(order.getPaymentStatus(), payment.getPaymentMethod()));
        payment.setPaymentDate(order.getCreatedAt() != null ? order.getCreatedAt() : LocalDate.now());
        payment.setTransactionId(resolveTransactionId(order, existingPayment));
        payment.setNotes(buildSystemNotes(order, invoice, payment.getPaymentMethod()));

        Payment savedPayment;
        if (existingPayment == null) {
            savedPayment = createPayment(payment);
        } else {
            savedPayment = updatePayment(existingPayment.getId(), payment);
        }

        return savedPayment;
    }

    private Payment preparePaymentForSave(Payment payment, Payment existingPayment) {
        if (payment == null) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Payment payload is required.");
        }

        Long orderId = payment.getOrderId();
        if (orderId == null) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Payment must be linked to a valid order.");
        }

        Order order = orderDao.getOrderById(orderId);
        if (order == null) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Linked order was not found.");
        }

        Invoice invoice = resolveInvoice(payment.getInvoiceId(), order);

        Payment preparedPayment = new Payment();
        preparedPayment.setId(existingPayment != null ? existingPayment.getId() : null);
        preparedPayment.setOrderId(order.getId());
        preparedPayment.setInvoiceId(invoice != null ? invoice.getId() : null);
        preparedPayment.setCustomerName(resolveCustomerName(payment.getCustomerName(), order, invoice));
        preparedPayment.setAmount(resolveAmount(payment.getAmount(), order, invoice));
        preparedPayment.setPaymentMethod(resolvePaymentMethod(payment.getPaymentMethod(), order, invoice));
        preparedPayment.setTransactionId(resolveProvidedTransactionId(payment.getTransactionId(), existingPayment, order));
        preparedPayment.setPaymentStatus(resolvePaymentStatus(payment.getPaymentStatus(), order, invoice, preparedPayment.getPaymentMethod()));
        preparedPayment.setPaymentDate(resolvePaymentDate(payment.getPaymentDate(), order));
        preparedPayment.setNotes(normalizeNotes(payment.getNotes()));
        preparedPayment.setCreatedAt(existingPayment != null ? existingPayment.getCreatedAt() : LocalDate.now());
        preparedPayment.setUpdatedAt(LocalDate.now());
        return preparedPayment;
    }

    private Invoice resolveInvoice(Long requestedInvoiceId, Order order) {
        Invoice latestInvoice = invoiceDao.getLatestInvoiceByOrderId(order.getId());
        if (requestedInvoiceId == null) {
            return latestInvoice;
        }

        Invoice invoice = invoiceDao.getInvoiceById(requestedInvoiceId);
        if (invoice == null) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Linked invoice was not found.");
        }
        if (invoice.getOrderId() == null || !invoice.getOrderId().equals(order.getId())) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "The selected invoice does not belong to the selected order.");
        }

        return invoice;
    }

    private String resolveCustomerName(String requestedCustomerName, Order order, Invoice invoice) {
        String customerName = normalizeText(requestedCustomerName, "");
        if (!customerName.isEmpty()) {
            return customerName;
        }
        if (invoice != null) {
            customerName = normalizeText(invoice.getCustomerName(), "");
            if (!customerName.isEmpty()) {
                return customerName;
            }
        }
        customerName = normalizeText(order.getCustomerName(), "");
        if (!customerName.isEmpty()) {
            return customerName;
        }

        throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Customer name is required for the payment record.");
    }

    private Double resolveAmount(Double requestedAmount, Order order, Invoice invoice) {
        Double amount = normalizeAmount(requestedAmount);
        if (amount > 0) {
            return amount;
        }
        if (invoice != null && normalizeAmount(invoice.getTotalAmount()) > 0) {
            return normalizeAmount(invoice.getTotalAmount());
        }
        amount = normalizeAmount(order.getTotalAmount());
        if (amount > 0) {
            return amount;
        }

        throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Payment amount must be greater than zero.");
    }

    private String resolvePaymentMethod(String requestedMethod, Order order, Invoice invoice) {
        String method = normalizePaymentMethod(requestedMethod);
        if (!method.isEmpty()) {
            return method;
        }
        if (invoice != null) {
            method = normalizePaymentMethod(invoice.getPaymentMethod());
            if (!method.isEmpty()) {
                return method;
            }
        }
        method = normalizePaymentMethod(order.getPaymentMethod());
        if (!method.isEmpty()) {
            return method;
        }

        return "Cash On Delivery";
    }

    private String resolveProvidedTransactionId(String requestedTransactionId, Payment existingPayment, Order order) {
        String transactionId = normalizeText(requestedTransactionId, "");
        if (transactionId.isEmpty()) {
            transactionId = resolveTransactionId(order, existingPayment);
        }

        Payment matchedPayment = paymentDao.getPaymentByTransactionId(transactionId);
        if (matchedPayment != null && (existingPayment == null || !matchedPayment.getId().equals(existingPayment.getId()))) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Transaction ID already exists.");
        }

        return transactionId;
    }

    private String resolvePaymentStatus(String requestedStatus, Order order, Invoice invoice, String paymentMethod) {
        String status = normalizePaymentStatus(requestedStatus, paymentMethod);
        if (!status.isEmpty()) {
            return status;
        }
        if (invoice != null) {
            status = normalizePaymentStatus(invoice.getPaymentStatus(), paymentMethod);
            if (!status.isEmpty()) {
                return status;
            }
        }

        return normalizePaymentStatus(order.getPaymentStatus(), paymentMethod);
    }

    private LocalDate resolvePaymentDate(LocalDate requestedPaymentDate, Order order) {
        if (requestedPaymentDate != null) {
            return requestedPaymentDate;
        }
        if (order.getCreatedAt() != null) {
            return order.getCreatedAt();
        }
        return LocalDate.now();
    }

    private void syncLinkedRecords(Payment payment) {
        if (payment == null || payment.getOrderId() == null) {
            return;
        }

        orderDao.updateOrderPaymentSnapshot(
                payment.getOrderId(),
                payment.getPaymentMethod(),
                payment.getPaymentStatus()
        );

        if (payment.getInvoiceId() != null) {
            invoiceDao.updateInvoicePaymentSnapshot(
                    payment.getInvoiceId(),
                    payment.getPaymentMethod(),
                    payment.getPaymentStatus()
            );
        }
    }

    private String resolveTransactionId(Order order, Payment existingPayment) {
        if (existingPayment != null) {
            String currentTransactionId = normalizeText(existingPayment.getTransactionId(), "");
            if (!currentTransactionId.isEmpty()) {
                return currentTransactionId;
            }
        }

        String orderReference = normalizeText(order.getOrderId(), "");
        if (orderReference.isEmpty()) {
            orderReference = String.valueOf(order.getId());
        }

        String methodPrefix = normalizePaymentMethod(order.getPaymentMethod())
                .replaceAll("[^A-Za-z0-9]", "")
                .toUpperCase();
        if (methodPrefix.isEmpty()) {
            methodPrefix = "PAY";
        }

        return methodPrefix + "-" + orderReference;
    }

    private String buildSystemNotes(Order order, Invoice invoice, String paymentMethod) {
        StringBuilder notes = new StringBuilder("Auto-synced from order ");
        notes.append(normalizeText(order.getOrderId(), String.valueOf(order.getId())));
        if (invoice != null && invoice.getInvoiceNumber() != null && !invoice.getInvoiceNumber().isBlank()) {
            notes.append(" and invoice ").append(invoice.getInvoiceNumber().trim());
        }
        if (!normalizeText(paymentMethod, "").isEmpty()) {
            notes.append(" using ").append(paymentMethod);
        }
        return notes.toString();
    }

    private String normalizeText(String value, String fallback) {
        if (value == null) {
            return fallback;
        }
        String normalized = value.trim();
        return normalized.isEmpty() ? fallback : normalized;
    }

    private String normalizeNotes(String notes) {
        return notes == null ? "" : notes.trim();
    }

    private Double normalizeAmount(Double amount) {
        return amount == null ? 0D : amount;
    }

    private String normalizePaymentMethod(String paymentMethod) {
        return normalizeText(paymentMethod, "");
    }

    private String normalizePaymentStatus(String paymentStatus, String paymentMethod) {
        String normalized = normalizeText(paymentStatus, "");
        if (!normalized.isEmpty()) {
            return normalized;
        }

        String method = normalizePaymentMethod(paymentMethod).toLowerCase();
        if (method.contains("cash")) {
            return "Pending";
        }

        return "Pending";
    }
}
