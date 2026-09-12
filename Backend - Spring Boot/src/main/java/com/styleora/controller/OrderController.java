package com.styleora.controller;

import com.styleora.dto.OrderDetailsResponse;
import com.styleora.dto.OrderRequest;
import com.styleora.dto.OrderStatusUpdateRequest;
import com.styleora.dto.OrderStatusUpdateResponse;
import com.styleora.model.Order;
import com.styleora.security.AuthenticatedUser;
import com.styleora.service.OrderService;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.server.ResponseStatusException;

import java.util.List;

@RestController
@RequestMapping("/orders")
public class OrderController {

    private final OrderService orderService;

    public OrderController(OrderService orderService) {
        this.orderService = orderService;
    }

    @PostMapping("/create")
    public OrderDetailsResponse createOrder(
            @Valid @RequestBody OrderRequest orderRequest,
            @AuthenticationPrincipal AuthenticatedUser authenticatedUser
    ) {
        if (authenticatedUser != null && authenticatedUser.hasRole("CUSTOMER")) {
            return orderService.createOrderForCustomer(authenticatedUser.getEmail(), orderRequest);
        }
        return orderService.createOrder(orderRequest);
    }

    @GetMapping("/list")
    public List<Order> getAllOrders() {
        return orderService.getAllOrders();
    }

    @GetMapping("/my")
    public ResponseEntity<List<OrderDetailsResponse>> getMyOrders(@AuthenticationPrincipal AuthenticatedUser authenticatedUser) {
        AuthenticatedUser customer = requireCustomer(authenticatedUser);
        return ResponseEntity.ok(orderService.getOrdersByCustomerEmail(customer.getEmail()));
    }

    @GetMapping("/my/{id}")
    public ResponseEntity<OrderDetailsResponse> getMyOrderById(
            @PathVariable Long id,
            @AuthenticationPrincipal AuthenticatedUser authenticatedUser
    ) {
        AuthenticatedUser customer = requireCustomer(authenticatedUser);
        return ResponseEntity.ok(orderService.getCustomerOrderById(id, customer.getEmail()));
    }

    @GetMapping("/my/reference/{orderId}")
    public ResponseEntity<OrderDetailsResponse> getMyOrderByReference(
            @PathVariable String orderId,
            @AuthenticationPrincipal AuthenticatedUser authenticatedUser
    ) {
        AuthenticatedUser customer = requireCustomer(authenticatedUser);
        return ResponseEntity.ok(orderService.getCustomerOrderByOrderId(orderId, customer.getEmail()));
    }

    @GetMapping("/{id}")
    public OrderDetailsResponse getOrderById(@PathVariable Long id) {
        return orderService.getOrderById(id);
    }

    @PutMapping("/update/{id}")
    public OrderDetailsResponse updateOrder(@PathVariable Long id, @RequestBody OrderRequest orderRequest) {
        return orderService.updateOrder(id, orderRequest);
    }

    @PutMapping("/update")
    public OrderDetailsResponse updateOrderLegacy(@RequestBody OrderRequest orderRequest) {
        if (orderRequest.getId() == null) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Order id is required");
        }
        return orderService.updateOrder(orderRequest.getId(), orderRequest);
    }

    @PutMapping("/status/{id}")
    public OrderStatusUpdateResponse updateOrderStatus(
            @PathVariable Long id,
            @RequestBody OrderStatusUpdateRequest statusUpdateRequest
    ) {
        return orderService.updateOrderStatus(id, statusUpdateRequest);
    }

    @DeleteMapping("/delete/{id}")
    public String deleteOrder(@PathVariable Long id) {
        orderService.deleteOrder(id);
        return "Order deleted successfully";
    }

    private AuthenticatedUser requireCustomer(AuthenticatedUser authenticatedUser) {
        if (authenticatedUser == null || !authenticatedUser.hasRole("CUSTOMER")) {
            throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Customer authentication is required.");
        }

        return authenticatedUser;
    }
}
