package com.styleora.dao;

import com.styleora.model.Attribute;
import jakarta.persistence.EntityManager;
import jakarta.persistence.PersistenceContext;
import jakarta.transaction.Transactional;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
@Transactional
public class AttributeDao {

    @PersistenceContext
    private EntityManager entityManager;

    public Attribute saveAttribute(Attribute attribute) {
        entityManager.persist(attribute);
        return attribute;
    }

    public List<Attribute> getAllAttributes() {
        return entityManager
                .createQuery("from Attribute a order by a.id desc", Attribute.class)
                .getResultList();
    }

    public Attribute getAttributeById(Long id) {
        return entityManager.find(Attribute.class, id);
    }

    public Attribute updateAttribute(Long id, Attribute attribute) {
        Attribute existingAttribute = entityManager.find(Attribute.class, id);

        if (existingAttribute == null) {
            return null;
        }

        existingAttribute.setAttributeId(attribute.getAttributeId());
        existingAttribute.setAttributeName(attribute.getAttributeName());
        existingAttribute.setAttributeType(attribute.getAttributeType());
        existingAttribute.setValues(attribute.getValues());
        existingAttribute.setStatus(attribute.getStatus());
        existingAttribute.setCreatedAt(attribute.getCreatedAt());
        existingAttribute.setUpdatedAt(attribute.getUpdatedAt());
        existingAttribute.setNotes(attribute.getNotes());

        return existingAttribute;
    }

    public boolean deleteAttribute(Long id) {
        Attribute attribute = entityManager.find(Attribute.class, id);
        if (attribute == null) {
            return false;
        }

        entityManager.remove(attribute);
        return true;
    }
}
