package com.styleora.controller;

import com.styleora.model.PurchaseReturn;
import com.styleora.service.PurchaseReturnService;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/purchase-returns")
public class PurchaseReturnController {

    private final PurchaseReturnService purchaseReturnService;

    public PurchaseReturnController(PurchaseReturnService purchaseReturnService) {
        this.purchaseReturnService = purchaseReturnService;
    }

    @PostMapping("/create")
    public ResponseEntity<?> createPurchaseReturn(@RequestBody PurchaseReturn purchaseReturn) {
        purchaseReturn.setId(null);
        return ResponseEntity.status(HttpStatus.CREATED).body(purchaseReturnService.createPurchaseReturn(purchaseReturn));
    }

    @GetMapping("/list")
    public List<PurchaseReturn> getAllPurchaseReturns() {
        return purchaseReturnService.getAllPurchaseReturns();
    }

    @GetMapping("/{id}")
    public ResponseEntity<PurchaseReturn> getPurchaseReturnById(@PathVariable Long id) {
        PurchaseReturn purchaseReturn = purchaseReturnService.getPurchaseReturnById(id);
        if (purchaseReturn == null) {
            return ResponseEntity.notFound().build();
        }

        return ResponseEntity.ok(purchaseReturn);
    }

    @PutMapping("/update/{id}")
    public ResponseEntity<PurchaseReturn> updatePurchaseReturn(@PathVariable Long id, @RequestBody PurchaseReturn purchaseReturn) {
        PurchaseReturn updatedPurchaseReturn = purchaseReturnService.updatePurchaseReturn(id, purchaseReturn);
        if (updatedPurchaseReturn == null) {
            return ResponseEntity.notFound().build();
        }

        return ResponseEntity.ok(updatedPurchaseReturn);
    }

    @DeleteMapping("/delete/{id}")
    public ResponseEntity<Void> deletePurchaseReturn(@PathVariable Long id) {
        boolean deleted = purchaseReturnService.deletePurchaseReturn(id);
        if (!deleted) {
            return ResponseEntity.notFound().build();
        }

        return ResponseEntity.noContent().build();
    }
}
