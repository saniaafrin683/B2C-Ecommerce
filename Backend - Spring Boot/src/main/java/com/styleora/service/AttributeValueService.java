package com.styleora.service;

import com.styleora.dao.AttributeValueDao;
import com.styleora.model.AttributeValue;
import org.springframework.stereotype.Service;

import java.time.LocalDate;
import java.util.List;

@Service
public class AttributeValueService {

    private final AttributeValueDao attributeValueDao;

    public AttributeValueService(AttributeValueDao attributeValueDao) {
        this.attributeValueDao = attributeValueDao;
    }

    public AttributeValue createAttributeValue(AttributeValue attributeValue) {
        LocalDate today = LocalDate.now();
        if (attributeValue.getCreatedAt() == null) {
            attributeValue.setCreatedAt(today);
        }
        attributeValue.setUpdatedAt(today);
        return attributeValueDao.saveAttributeValue(attributeValue);
    }

    public List<AttributeValue> getAllAttributeValues() {
        return attributeValueDao.getAllAttributeValues();
    }

    public AttributeValue getAttributeValueById(Long id) {
        return attributeValueDao.getAttributeValueById(id);
    }

    public List<AttributeValue> getAttributeValuesByAttributeId(Long attributeId) {
        return attributeValueDao.getAttributeValuesByAttributeId(attributeId);
    }

    public AttributeValue updateAttributeValue(Long id, AttributeValue attributeValue) {
        AttributeValue existingAttributeValue = attributeValueDao.getAttributeValueById(id);
        if (existingAttributeValue == null) {
            return null;
        }

        attributeValue.setCreatedAt(existingAttributeValue.getCreatedAt());
        attributeValue.setUpdatedAt(LocalDate.now());
        return attributeValueDao.updateAttributeValue(id, attributeValue);
    }

    public boolean deleteAttributeValue(Long id) {
        return attributeValueDao.deleteAttributeValue(id);
    }
}
