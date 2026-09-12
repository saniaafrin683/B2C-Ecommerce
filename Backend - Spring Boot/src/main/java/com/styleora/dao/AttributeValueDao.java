package com.styleora.dao;

import com.styleora.model.Attribute;
import com.styleora.model.AttributeValue;
import jakarta.persistence.EntityManager;
import jakarta.persistence.PersistenceContext;
import jakarta.transaction.Transactional;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
@Transactional
public class AttributeValueDao {

    @PersistenceContext
    private EntityManager entityManager;

    public AttributeValue saveAttributeValue(AttributeValue attributeValue) {
        attributeValue.setAttribute(resolveAttribute(attributeValue));
        entityManager.persist(attributeValue);
        return attributeValue;
    }

    public List<AttributeValue> getAllAttributeValues() {
        return entityManager
                .createQuery("select av from AttributeValue av join fetch av.attribute order by av.id desc", AttributeValue.class)
                .getResultList();
    }

    public AttributeValue getAttributeValueById(Long id) {
        List<AttributeValue> values = entityManager
                .createQuery("select av from AttributeValue av join fetch av.attribute where av.id = :id", AttributeValue.class)
                .setParameter("id", id)
                .getResultList();

        return values.isEmpty() ? null : values.get(0);
    }

    public List<AttributeValue> getAttributeValuesByAttributeId(Long attributeId) {
        return entityManager
                .createQuery("select av from AttributeValue av join fetch av.attribute where av.attribute.id = :attributeId order by av.id desc", AttributeValue.class)
                .setParameter("attributeId", attributeId)
                .getResultList();
    }

    public AttributeValue updateAttributeValue(Long id, AttributeValue attributeValue) {
        AttributeValue existingAttributeValue = entityManager.find(AttributeValue.class, id);

        if (existingAttributeValue == null) {
            return null;
        }

        existingAttributeValue.setAttribute(resolveAttribute(attributeValue));
        existingAttributeValue.setValue(attributeValue.getValue());
        existingAttributeValue.setStatus(attributeValue.getStatus());
        existingAttributeValue.setCreatedAt(attributeValue.getCreatedAt());
        existingAttributeValue.setUpdatedAt(attributeValue.getUpdatedAt());

        return existingAttributeValue;
    }

    public boolean deleteAttributeValue(Long id) {
        AttributeValue attributeValue = entityManager.find(AttributeValue.class, id);
        if (attributeValue == null) {
            return false;
        }

        entityManager.remove(attributeValue);
        return true;
    }

    private Attribute resolveAttribute(AttributeValue attributeValue) {
        Long resolvedAttributeId = attributeValue.getAttributeId();

        if (resolvedAttributeId == null && attributeValue.getAttribute() != null) {
            resolvedAttributeId = attributeValue.getAttribute().getId();
        }

        if (resolvedAttributeId == null) {
            return null;
        }

        return entityManager.find(Attribute.class, resolvedAttributeId);
    }
}
