package com.styleora.controller;

import com.styleora.model.ShippingMethod;
import com.styleora.service.ShippingMethodService;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequestMapping("/shipping-methods")
public class ShippingMethodController {

    private final ShippingMethodService shippingMethodService;

    public ShippingMethodController(ShippingMethodService shippingMethodService) {
        this.shippingMethodService = shippingMethodService;
    }

    @PostMapping("/create")
    public ResponseEntity<ShippingMethod> createShippingMethod(@RequestBody ShippingMethod shippingMethod) {
        shippingMethod.setId(null);
        return ResponseEntity.status(HttpStatus.CREATED).body(shippingMethodService.createShippingMethod(shippingMethod));
    }

    @GetMapping("/list")
    public List<ShippingMethod> getAllShippingMethods() {
        return shippingMethodService.getAllShippingMethods();
    }

    @GetMapping("/{id}")
    public ResponseEntity<ShippingMethod> getShippingMethodById(@PathVariable Long id) {
        ShippingMethod shippingMethod = shippingMethodService.getShippingMethodById(id);
        if (shippingMethod == null) {
            return ResponseEntity.notFound().build();
        }

        return ResponseEntity.ok(shippingMethod);
    }

    @PutMapping("/update/{id}")
    public ResponseEntity<ShippingMethod> updateShippingMethod(@PathVariable Long id, @RequestBody ShippingMethod shippingMethod) {
        ShippingMethod updatedShippingMethod = shippingMethodService.updateShippingMethod(id, shippingMethod);
        if (updatedShippingMethod == null) {
            return ResponseEntity.notFound().build();
        }

        return ResponseEntity.ok(updatedShippingMethod);
    }

    @DeleteMapping("/delete/{id}")
    public ResponseEntity<Void> deleteShippingMethod(@PathVariable Long id) {
        boolean deleted = shippingMethodService.deleteShippingMethod(id);
        if (!deleted) {
            return ResponseEntity.notFound().build();
        }

        return ResponseEntity.noContent().build();
    }
}
