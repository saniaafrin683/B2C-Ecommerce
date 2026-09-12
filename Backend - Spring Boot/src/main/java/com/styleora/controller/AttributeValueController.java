package com.styleora.controller;

import com.styleora.model.AttributeValue;
import com.styleora.service.AttributeValueService;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/attribute-values")
public class AttributeValueController {

    private final AttributeValueService attributeValueService;

    public AttributeValueController(AttributeValueService attributeValueService) {
        this.attributeValueService = attributeValueService;
    }

    @PostMapping("/create")
    public ResponseEntity<AttributeValue> createAttributeValue(@RequestBody AttributeValue attributeValue) {
        attributeValue.setId(null);
        return ResponseEntity.status(HttpStatus.CREATED).body(attributeValueService.createAttributeValue(attributeValue));
    }

    @GetMapping("/list")
    public List<AttributeValue> getAllAttributeValues() {
        return attributeValueService.getAllAttributeValues();
    }

    @GetMapping("/{id}")
    public ResponseEntity<AttributeValue> getAttributeValueById(@PathVariable Long id) {
        AttributeValue attributeValue = attributeValueService.getAttributeValueById(id);
        if (attributeValue == null) {
            return ResponseEntity.notFound().build();
        }

        return ResponseEntity.ok(attributeValue);
    }

    @GetMapping("/by-attribute/{attributeId}")
    public List<AttributeValue> getAttributeValuesByAttributeId(@PathVariable Long attributeId) {
        return attributeValueService.getAttributeValuesByAttributeId(attributeId);
    }

    @PutMapping("/update/{id}")
    public ResponseEntity<AttributeValue> updateAttributeValue(@PathVariable Long id, @RequestBody AttributeValue attributeValue) {
        AttributeValue updatedAttributeValue = attributeValueService.updateAttributeValue(id, attributeValue);
        if (updatedAttributeValue == null) {
            return ResponseEntity.notFound().build();
        }

        return ResponseEntity.ok(updatedAttributeValue);
    }

    @DeleteMapping("/delete/{id}")
    public ResponseEntity<Void> deleteAttributeValue(@PathVariable Long id) {
        boolean deleted = attributeValueService.deleteAttributeValue(id);
        if (!deleted) {
            return ResponseEntity.notFound().build();
        }

        return ResponseEntity.noContent().build();
    }
}
