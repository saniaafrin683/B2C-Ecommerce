package com.styleora.controller;

import com.styleora.dto.ShipmentStatusUpdateRequest;
import com.styleora.model.Shipment;
import com.styleora.security.AuthenticatedUser;
import com.styleora.service.ShipmentService;
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
import org.springframework.security.core.annotation.AuthenticationPrincipal;

import java.util.List;

@RestController
@RequestMapping("/shipments")
public class ShipmentController {

    private final ShipmentService shipmentService;

    public ShipmentController(ShipmentService shipmentService) {
        this.shipmentService = shipmentService;
    }

    @PostMapping({"", "/create"})
    public ResponseEntity<Shipment> createShipment(@RequestBody Shipment shipment) {
        shipment.setId(null);
        return ResponseEntity.status(HttpStatus.CREATED).body(shipmentService.createShipment(shipment));
    }

    @GetMapping({"", "/list"})
    public List<Shipment> getAllShipments() {
        return shipmentService.getAllShipments();
    }

    @GetMapping("/order/{orderId}")
    public ResponseEntity<Shipment> getShipmentByOrderId(
            @PathVariable Long orderId,
            @AuthenticationPrincipal AuthenticatedUser authenticatedUser
    ) {
        return ResponseEntity.ok(shipmentService.getShipmentByOrderId(orderId, authenticatedUser));
    }

    @GetMapping("/{id}")
    public ResponseEntity<Shipment> getShipmentById(@PathVariable Long id) {
        Shipment shipment = shipmentService.getShipmentById(id);
        if (shipment == null) {
            return ResponseEntity.notFound().build();
        }

        return ResponseEntity.ok(shipment);
    }

    @PutMapping({"/{id}", "/update/{id}"})
    public ResponseEntity<Shipment> updateShipment(@PathVariable Long id, @RequestBody Shipment shipment) {
        return ResponseEntity.ok(shipmentService.updateShipment(id, shipment));
    }

    @PutMapping("/status/{id}")
    public ResponseEntity<Shipment> updateShipmentStatus(@PathVariable Long id, @RequestBody ShipmentStatusUpdateRequest request) {
        return ResponseEntity.ok(shipmentService.updateShipmentStatus(id, request));
    }

    @DeleteMapping({"/{id}", "/delete/{id}"})
    public ResponseEntity<Void> deleteShipment(@PathVariable Long id) {
        boolean deleted = shipmentService.deleteShipment(id);
        if (!deleted) {
            return ResponseEntity.notFound().build();
        }

        return ResponseEntity.noContent().build();
    }
}
