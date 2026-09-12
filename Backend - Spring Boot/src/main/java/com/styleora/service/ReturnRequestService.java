package com.styleora.service;

import com.styleora.dao.CustomerDao;
import com.styleora.dao.OrderDao;
import com.styleora.dao.ReturnRequestDao;
import com.styleora.dto.ReturnRequestCreateRequest;
import com.styleora.dto.ReturnRequestStatusUpdateRequest;
import com.styleora.model.Customer;
import com.styleora.model.Order;
import com.styleora.model.ReturnRequest;
import com.styleora.security.AuthenticatedUser;
import org.springframework.stereotype.Service;
import org.springframework.util.StringUtils;
import org.springframework.web.server.ResponseStatusException;
import org.springframework.http.HttpStatus;

import jakarta.transaction.Transactional;

import java.util.List;
import java.util.Locale;

@Service
public class ReturnRequestService {

    private static final String STATUS_PENDING = "Pending";
    private static final String STATUS_APPROVED = "Approved";
    private static final String STATUS_REJECTED = "Rejected";
    private static final String STATUS_REFUNDED = "Refunded";

    private final ReturnRequestDao returnRequestDao;
    private final OrderDao orderDao;
    private final CustomerDao customerDao;

    public ReturnRequestService(ReturnRequestDao returnRequestDao, OrderDao orderDao, CustomerDao customerDao) {
        this.returnRequestDao = returnRequestDao;
        this.orderDao = orderDao;
        this.customerDao = customerDao;
    }

    @Transactional
    public ReturnRequest createReturnRequest(ReturnRequestCreateRequest request, AuthenticatedUser authenticatedUser) {
        AuthenticatedUser customerUser = requireCustomer(authenticatedUser);
        Customer customer = requireCustomerRecord(customerUser);
        Long orderId = requirePositiveId(request != null ? request.getOrderId() : null, "Order id is required.");
        Order order = requireOwnedOrder(orderId, customer.getEmail());
        validateOrderDelivered(order);

        ReturnRequest existingRequest = returnRequestDao.getReturnRequestByOrderIdAndCustomerId(order.getId(), customer.getId());
        if (existingRequest != null) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "A return request already exists for this order.");
        }

        ReturnRequest returnRequest = new ReturnRequest();
        returnRequest.setOrderId(order.getId());
        returnRequest.setCustomerId(customer.getId());
        returnRequest.setProductId(request != null ? request.getProductId() : null);
        returnRequest.setReason(requireReason(request != null ? request.getReason() : null));
        returnRequest.setNote(trimToNull(request != null ? request.getNote() : null));
        returnRequest.setStatus(STATUS_PENDING);

        ReturnRequest savedRequest = returnRequestDao.saveReturnRequest(returnRequest);
        enrich(savedRequest);
        return savedRequest;
    }

    @Transactional
    public ReturnRequest createReturnRequestFromAdmin(ReturnRequestCreateRequest request) {
        Long orderId = requirePositiveId(request != null ? request.getOrderId() : null, "Order id is required.");
        Long customerId = requirePositiveId(request != null ? request.getCustomerId() : null, "Customer id is required.");
        Order order = requireOrder(orderId);
        Customer customer = requireCustomerById(customerId);
        validateOrderDelivered(order);
        validateCustomerOwnsOrder(customer, order);

        ReturnRequest existingRequest = returnRequestDao.getReturnRequestByOrderIdAndCustomerId(order.getId(), customer.getId());
        if (existingRequest != null) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "A return request already exists for this order.");
        }

        ReturnRequest returnRequest = new ReturnRequest();
        returnRequest.setOrderId(order.getId());
        returnRequest.setCustomerId(customer.getId());
        returnRequest.setProductId(request != null ? request.getProductId() : null);
        returnRequest.setReason(requireReason(request != null ? request.getReason() : null));
        returnRequest.setNote(trimToNull(request != null ? request.getNote() : null));
        returnRequest.setStatus(normalizeStatus(null));

        ReturnRequest savedRequest = returnRequestDao.saveReturnRequest(returnRequest);
        enrich(savedRequest);
        return savedRequest;
    }

    public List<ReturnRequest> getAllReturnRequests() {
        List<ReturnRequest> requests = returnRequestDao.getAllReturnRequests();
        requests.forEach(this::enrich);
        return requests;
    }

    public ReturnRequest getReturnRequestById(Long id) {
        ReturnRequest returnRequest = returnRequestDao.getReturnRequestById(id);
        if (returnRequest == null) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "Return request not found.");
        }
        enrich(returnRequest);
        return returnRequest;
    }

    public List<ReturnRequest> getCustomerReturnRequests(Long customerId, AuthenticatedUser authenticatedUser) {
        if (customerId == null || customerId <= 0) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Customer id is required.");
        }

        if (authenticatedUser != null && authenticatedUser.hasRole("CUSTOMER") && !customerId.equals(authenticatedUser.getId())) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "You do not have permission to access these return requests.");
        }

        List<ReturnRequest> requests = returnRequestDao.getReturnRequestsByCustomerId(customerId);
        requests.forEach(this::enrich);
        return requests;
    }

    @Transactional
    public ReturnRequest updateReturnRequestStatus(Long id, ReturnRequestStatusUpdateRequest request) {
        ReturnRequest existingRequest = returnRequestDao.getReturnRequestByIdForUpdate(id);
        if (existingRequest == null) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "Return request not found.");
        }

        existingRequest.setStatus(normalizeStatus(request != null ? request.getStatus() : null));
        if (request != null && request.getNote() != null) {
            existingRequest.setNote(trimToNull(request.getNote()));
        }

        ReturnRequest updatedRequest = returnRequestDao.updateReturnRequest(existingRequest);
        enrich(updatedRequest);
        return updatedRequest;
    }

    public boolean deleteReturnRequest(Long id) {
        return returnRequestDao.deleteReturnRequest(id);
    }

    private void enrich(ReturnRequest returnRequest) {
        if (returnRequest == null) {
            return;
        }

        Order order = orderDao.getOrderById(returnRequest.getOrderId());
        if (order != null) {
            returnRequest.setOrderReference(
                    StringUtils.hasText(order.getOrderId()) ? order.getOrderId() : "ORD-" + order.getId()
            );
            if (!StringUtils.hasText(returnRequest.getCustomerName())) {
                returnRequest.setCustomerName(order.getCustomerName());
            }
        }

        if (!StringUtils.hasText(returnRequest.getCustomerName()) && returnRequest.getCustomerId() != null) {
            Customer customer = customerDao.getCustomerById(returnRequest.getCustomerId());
            if (customer != null) {
                returnRequest.setCustomerName(customer.getFullName());
            }
        }
    }

    private AuthenticatedUser requireCustomer(AuthenticatedUser authenticatedUser) {
        if (authenticatedUser == null || !authenticatedUser.hasRole("CUSTOMER")) {
            throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Customer authentication is required.");
        }
        return authenticatedUser;
    }

    private Customer requireCustomerRecord(AuthenticatedUser authenticatedUser) {
        Customer customer = customerDao.findByEmail(authenticatedUser.getEmail());
        if (customer == null) {
            throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Customer account not found.");
        }
        return customer;
    }

    private Customer requireCustomerById(Long customerId) {
        Customer customer = customerDao.getCustomerById(customerId);
        if (customer == null) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "Customer not found.");
        }
        return customer;
    }

    private Order requireOrder(Long orderId) {
        Order order = orderDao.getOrderById(orderId);
        if (order == null) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "Order not found.");
        }
        return order;
    }

    private Order requireOwnedOrder(Long orderId, String customerEmail) {
        Order order = orderDao.getOrderByIdAndCustomerEmail(orderId, customerEmail);
        if (order == null) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "Order not found.");
        }
        return order;
    }

    private void validateOrderDelivered(Order order) {
        if (!"delivered".equalsIgnoreCase(order.getOrderStatus())) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Only delivered orders can request a return.");
        }
    }

    private void validateCustomerOwnsOrder(Customer customer, Order order) {
        String customerEmail = customer.getEmail() == null ? "" : customer.getEmail().trim();
        String orderEmail = order.getCustomerEmail() == null ? "" : order.getCustomerEmail().trim();
        if (!customerEmail.equalsIgnoreCase(orderEmail)) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Selected customer does not own this order.");
        }
    }

    private Long requirePositiveId(Long id, String message) {
        if (id == null || id <= 0L) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, message);
        }
        return id;
    }

    private String requireReason(String reason) {
        String normalizedReason = trimToNull(reason);
        if (!StringUtils.hasText(normalizedReason)) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Return reason is required.");
        }
        return normalizedReason;
    }

    private String trimToNull(String value) {
        return StringUtils.hasText(value) ? value.trim() : null;
    }

    private String normalizeStatus(String status) {
        if (!StringUtils.hasText(status)) {
            return STATUS_PENDING;
        }

        String normalized = status.trim().toLowerCase(Locale.ROOT);
        return switch (normalized) {
            case "pending", "requested" -> STATUS_PENDING;
            case "approved" -> STATUS_APPROVED;
            case "rejected" -> STATUS_REJECTED;
            case "refunded" -> STATUS_REFUNDED;
            default -> throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Invalid return status.");
        };
    }
}
