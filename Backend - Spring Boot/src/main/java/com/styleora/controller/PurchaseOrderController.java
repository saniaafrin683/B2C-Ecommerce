package com.styleora.controller;

import com.styleora.model.PurchaseOrder;
import com.styleora.service.PurchaseOrderService;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/purchase-orders")
public class PurchaseOrderController {

    private final PurchaseOrderService purchaseOrderService;

    public PurchaseOrderController(PurchaseOrderService purchaseOrderService) {
        this.purchaseOrderService = purchaseOrderService;
    }

    @PostMapping("/create")
    public ResponseEntity<?> createPurchaseOrder(@RequestBody PurchaseOrder purchaseOrder) {
        purchaseOrder.setId(null);
        return ResponseEntity.status(HttpStatus.CREATED).body(purchaseOrderService.createPurchaseOrder(purchaseOrder));
    }

    @GetMapping("/list")
    public List<PurchaseOrder> getAllPurchaseOrders() {
        return purchaseOrderService.getAllPurchaseOrders();
    }

    @GetMapping("/{id}")
    public ResponseEntity<PurchaseOrder> getPurchaseOrderById(@PathVariable Long id) {
        PurchaseOrder purchaseOrder = purchaseOrderService.getPurchaseOrderById(id);
        if (purchaseOrder == null) {
            return ResponseEntity.notFound().build();
        }

        return ResponseEntity.ok(purchaseOrder);
    }

    @PutMapping("/update/{id}")
    public ResponseEntity<PurchaseOrder> updatePurchaseOrder(@PathVariable Long id, @RequestBody PurchaseOrder purchaseOrder) {
        PurchaseOrder updatedPurchaseOrder = purchaseOrderService.updatePurchaseOrder(id, purchaseOrder);
        if (updatedPurchaseOrder == null) {
            return ResponseEntity.notFound().build();
        }

        return ResponseEntity.ok(updatedPurchaseOrder);
    }

    @DeleteMapping("/delete/{id}")
    public ResponseEntity<Void> deletePurchaseOrder(@PathVariable Long id) {
        boolean deleted = purchaseOrderService.deletePurchaseOrder(id);
        if (!deleted) {
            return ResponseEntity.notFound().build();
        }

        return ResponseEntity.noContent().build();
    }
}
