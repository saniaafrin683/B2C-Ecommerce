package com.styleora.service;

import com.styleora.model.Attribute;
import com.styleora.model.AttributeValue;
import jakarta.persistence.EntityManager;
import jakarta.persistence.PersistenceContext;
import jakarta.transaction.Transactional;
import org.springframework.boot.CommandLineRunner;
import org.springframework.core.annotation.Order;
import org.springframework.stereotype.Service;

import java.time.LocalDate;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Set;

@Service
@Order(15)
@Transactional
public class AttributeSeedService implements CommandLineRunner {

    @PersistenceContext
    private EntityManager entityManager;

    @Override
    public void run(String... args) {
        Map<String, List<String>> seedData = new LinkedHashMap<>();
        seedData.put("Size", List.of("XS", "S", "M", "L", "XL", "XXL"));
        seedData.put("Color", List.of("Black", "White", "Red", "Blue", "Green", "Yellow", "Gray", "Navy", "Pink", "Brown"));
        seedData.put("Storage", List.of("32GB", "64GB", "128GB", "256GB", "512GB", "1TB"));
        seedData.put("RAM", List.of("2GB", "4GB", "6GB", "8GB", "12GB", "16GB", "32GB"));
        seedData.put("Weight", List.of("250g", "500g", "1kg", "2kg", "5kg", "10kg"));
        seedData.put("Material", List.of("Cotton", "Leather", "Denim", "Polyester", "Silk", "Plastic", "Metal"));
        seedData.put("Gender", List.of("Men", "Women", "Kids", "Unisex"));
        seedData.put("Condition", List.of("New", "Used", "Refurbished"));

        for (Map.Entry<String, List<String>> entry : seedData.entrySet()) {
            Attribute attribute = findAttributeByName(entry.getKey());
            if (attribute == null) {
                attribute = createAttribute(entry.getKey(), entry.getValue());
                entityManager.persist(attribute);
                entityManager.flush();
            } else {
                mergeAttributeMetadata(attribute, entry.getValue());
            }

            seedAttributeValues(attribute, entry.getValue());
        }
    }

    private Attribute createAttribute(String attributeName, List<String> values) {
        Attribute attribute = new Attribute();
        attribute.setAttributeId(buildAttributeCode(attributeName));
        attribute.setAttributeName(attributeName);
        attribute.setAttributeType(attributeName);
        attribute.setValues(String.join(", ", values));
        attribute.setStatus("Active");
        attribute.setCreatedAt(LocalDate.now());
        attribute.setUpdatedAt(LocalDate.now());
        attribute.setNotes("System-seeded admin attribute");
        return attribute;
    }

    private void mergeAttributeMetadata(Attribute attribute, List<String> seedValues) {
        if (isBlank(attribute.getAttributeId())) {
            attribute.setAttributeId(buildAttributeCode(attribute.getAttributeName()));
        }

        if (isBlank(attribute.getAttributeType())) {
            attribute.setAttributeType(attribute.getAttributeName());
        }

        if (isBlank(attribute.getStatus())) {
            attribute.setStatus("Active");
        }

        if (isBlank(attribute.getNotes())) {
            attribute.setNotes("System-seeded admin attribute");
        }

        attribute.setValues(buildMergedValueList(attribute.getValues(), seedValues));
        attribute.setUpdatedAt(LocalDate.now());
    }

    private void seedAttributeValues(Attribute attribute, List<String> seedValues) {
        for (String value : seedValues) {
            if (attributeValueExists(attribute.getId(), value)) {
                continue;
            }

            AttributeValue attributeValue = new AttributeValue();
            attributeValue.setAttribute(attribute);
            attributeValue.setValue(value);
            attributeValue.setStatus("Active");
            attributeValue.setCreatedAt(LocalDate.now());
            attributeValue.setUpdatedAt(LocalDate.now());
            entityManager.persist(attributeValue);
        }

        entityManager.flush();
    }

    private Attribute findAttributeByName(String attributeName) {
        List<Attribute> matches = entityManager.createQuery(
                        "select a from Attribute a where lower(a.attributeName) = lower(:name)",
                        Attribute.class
                )
                .setParameter("name", attributeName)
                .setMaxResults(1)
                .getResultList();

        return matches.isEmpty() ? null : matches.get(0);
    }

    private boolean attributeValueExists(Long attributeId, String value) {
        Long count = entityManager.createQuery(
                        "select count(av) from AttributeValue av where av.attribute.id = :attributeId and lower(av.value) = lower(:value)",
                        Long.class
                )
                .setParameter("attributeId", attributeId)
                .setParameter("value", value)
                .getSingleResult();

        return count != null && count > 0;
    }

    private String buildMergedValueList(String existingValues, List<String> seedValues) {
        Set<String> normalized = new LinkedHashSet<>();
        List<String> merged = new ArrayList<>();

        for (String value : seedValues) {
            addIfMissing(merged, normalized, value);
        }

        if (!isBlank(existingValues)) {
            for (String value : existingValues.split(",")) {
                addIfMissing(merged, normalized, value);
            }
        }

        return String.join(", ", merged);
    }

    private void addIfMissing(List<String> merged, Set<String> normalized, String value) {
        String trimmed = value == null ? "" : value.trim();
        if (trimmed.isEmpty()) {
            return;
        }

        String key = trimmed.toLowerCase(Locale.ROOT);
        if (normalized.add(key)) {
            merged.add(trimmed);
        }
    }

    private String buildAttributeCode(String attributeName) {
        return "ATTR_" + attributeName
                .toUpperCase(Locale.ROOT)
                .replaceAll("[^A-Z0-9]+", "_")
                .replaceAll("^_+|_+$", "");
    }

    private boolean isBlank(String value) {
        return value == null || value.trim().isEmpty();
    }
}
