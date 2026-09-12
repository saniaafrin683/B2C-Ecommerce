package com.styleora.controller;

import com.styleora.dto.PurchaseRequest;
import com.styleora.dto.PurchaseResponse;
import com.styleora.service.PurchaseService;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/purchases")
public class PurchaseController {

    private final PurchaseService purchaseService;

    public PurchaseController(PurchaseService purchaseService) {
        this.purchaseService = purchaseService;
    }

    @PostMapping("/create")
    public ResponseEntity<PurchaseResponse> createPurchase(@RequestBody PurchaseRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED).body(purchaseService.createPurchase(request));
    }

    @GetMapping("/list")
    public List<PurchaseResponse> getAllPurchases() {
        return purchaseService.getAllPurchases();
    }

    @GetMapping({"/details/{id}", "/{id}"})
    public ResponseEntity<PurchaseResponse> getPurchaseById(@PathVariable Long id) {
        PurchaseResponse purchase = purchaseService.getPurchaseById(id);
        if (purchase == null) {
            return ResponseEntity.notFound().build();
        }

        return ResponseEntity.ok(purchase);
    }

    @PutMapping("/update/{id}")
    public ResponseEntity<PurchaseResponse> updatePurchase(@PathVariable Long id, @RequestBody PurchaseRequest request) {
        PurchaseResponse updatedPurchase = purchaseService.updatePurchase(id, request);
        if (updatedPurchase == null) {
            return ResponseEntity.notFound().build();
        }

        return ResponseEntity.ok(updatedPurchase);
    }

    @DeleteMapping("/delete/{id}")
    public ResponseEntity<Void> deletePurchase(@PathVariable Long id) {
        boolean deleted = purchaseService.deletePurchase(id);
        if (!deleted) {
            return ResponseEntity.notFound().build();
        }

        return ResponseEntity.noContent().build();
    }
}
