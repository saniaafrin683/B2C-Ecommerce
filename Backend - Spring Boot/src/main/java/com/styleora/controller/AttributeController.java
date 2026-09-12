package com.styleora.controller;

import com.styleora.model.Attribute;
import com.styleora.service.AttributeService;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/attributes")
public class AttributeController {

    private final AttributeService attributeService;

    public AttributeController(AttributeService attributeService) {
        this.attributeService = attributeService;
    }

    @PostMapping("/create")
    public ResponseEntity<Attribute> createAttribute(@RequestBody Attribute attribute) {
        attribute.setId(null);
        return ResponseEntity.status(HttpStatus.CREATED).body(attributeService.createAttribute(attribute));
    }

    @GetMapping("/list")
    public List<Attribute> getAllAttributes() {
        return attributeService.getAllAttributes();
    }

    @GetMapping("/{id}")
    public ResponseEntity<Attribute> getAttributeById(@PathVariable Long id) {
        Attribute attribute = attributeService.getAttributeById(id);
        if (attribute == null) {
            return ResponseEntity.notFound().build();
        }

        return ResponseEntity.ok(attribute);
    }

    @PutMapping("/update/{id}")
    public ResponseEntity<Attribute> updateAttribute(@PathVariable Long id, @RequestBody Attribute attribute) {
        Attribute updatedAttribute = attributeService.updateAttribute(id, attribute);
        if (updatedAttribute == null) {
            return ResponseEntity.notFound().build();
        }

        return ResponseEntity.ok(updatedAttribute);
    }

    @DeleteMapping("/delete/{id}")
    public ResponseEntity<Void> deleteAttribute(@PathVariable Long id) {
        boolean deleted = attributeService.deleteAttribute(id);
        if (!deleted) {
            return ResponseEntity.notFound().build();
        }

        return ResponseEntity.noContent().build();
    }
}
