package com.styleora.service;

import com.styleora.dao.AttributeDao;
import com.styleora.model.Attribute;
import org.springframework.stereotype.Service;

import java.time.LocalDate;
import java.util.List;

@Service
public class AttributeService {

    private final AttributeDao attributeDao;

    public AttributeService(AttributeDao attributeDao) {
        this.attributeDao = attributeDao;
    }

    public Attribute createAttribute(Attribute attribute) {
        LocalDate today = LocalDate.now();
        if (attribute.getCreatedAt() == null) {
            attribute.setCreatedAt(today);
        }
        attribute.setUpdatedAt(today);
        return attributeDao.saveAttribute(attribute);
    }

    public List<Attribute> getAllAttributes() {
        return attributeDao.getAllAttributes();
    }

    public Attribute getAttributeById(Long id) {
        return attributeDao.getAttributeById(id);
    }

    public Attribute updateAttribute(Long id, Attribute attribute) {
        Attribute existingAttribute = attributeDao.getAttributeById(id);
        if (existingAttribute == null) {
            return null;
        }

        attribute.setCreatedAt(existingAttribute.getCreatedAt());
        attribute.setUpdatedAt(LocalDate.now());
        return attributeDao.updateAttribute(id, attribute);
    }

    public boolean deleteAttribute(Long id) {
        return attributeDao.deleteAttribute(id);
    }
}
