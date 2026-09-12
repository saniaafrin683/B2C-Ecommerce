package com.styleora.controller;

import com.styleora.dto.ReceivedOrderStatusUpdateRequest;
import java.util.List;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import com.styleora.model.ReceivedOrder;
import com.styleora.service.ReceivedOrderService;

@RestController
@RequestMapping({"/inventory/received-orders", "/received-orders"})
public class ReceivedOrderController {

    @Autowired
    private ReceivedOrderService receivedOrderService;

    @PostMapping({"", "/create"})
    public ReceivedOrder createReceivedOrder(@RequestBody ReceivedOrder order) {
        order.setId(null);
        return receivedOrderService.saveReceivedOrder(order);
    }

    @GetMapping({"", "/list"})
    public List<ReceivedOrder> getAllReceivedOrders() {
        return receivedOrderService.getAllReceivedOrders();
    }

    @GetMapping("/{id}")
    public ReceivedOrder getReceivedOrderById(@PathVariable Long id) {
        return receivedOrderService.getReceivedOrderById(id);
    }

    @PutMapping("/status/{id}")
    public ReceivedOrder updateReceivedOrderStatus(
            @PathVariable Long id,
            @RequestBody ReceivedOrderStatusUpdateRequest request
    ) {
        return receivedOrderService.updateStatus(id, request != null ? request.getStatus() : null);
    }

    @PutMapping({"/update/{id}", "/update"})
    public ReceivedOrder updateReceivedOrder(
            @PathVariable(required = false) Long id,
            @RequestBody ReceivedOrder order
    ) {
        Long targetId = id != null ? id : order.getId();
        return receivedOrderService.updateReceivedOrder(targetId, order);
    }

    @DeleteMapping("/delete/{id}")
    public String deleteReceivedOrder(@PathVariable Long id) {
        receivedOrderService.deleteReceivedOrder(id);
        return "Received order deleted successfully";
    }
}
