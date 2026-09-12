package com.styleora.dao;

import com.styleora.model.ShippingMethod;
import jakarta.persistence.EntityManager;
import jakarta.persistence.PersistenceContext;
import jakarta.transaction.Transactional;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
@Transactional
public class ShippingMethodDao {

    @PersistenceContext
    private EntityManager entityManager;

    public ShippingMethod saveShippingMethod(ShippingMethod shippingMethod) {
        shippingMethod.setId(null);
        entityManager.persist(shippingMethod);
        return shippingMethod;
    }

    public List<ShippingMethod> getAllShippingMethods() {
        return entityManager
                .createQuery("from ShippingMethod sm order by sm.sortOrder asc, sm.id desc", ShippingMethod.class)
                .getResultList();
    }

    public List<ShippingMethod> getActiveShippingMethods() {
        return entityManager
                .createQuery(
                        "from ShippingMethod sm where upper(coalesce(sm.status, 'ACTIVE')) = 'ACTIVE' order by sm.sortOrder asc, sm.id desc",
                        ShippingMethod.class
                )
                .getResultList();
    }

    public ShippingMethod getShippingMethodById(Long id) {
        return entityManager.find(ShippingMethod.class, id);
    }

    public void flush() {
        entityManager.flush();
    }

    public ShippingMethod updateShippingMethod(Long id, ShippingMethod shippingMethod) {
        ShippingMethod existingShippingMethod = entityManager.find(ShippingMethod.class, id);
        if (existingShippingMethod == null) {
            return null;
        }

        existingShippingMethod.setName(shippingMethod.getName());
        existingShippingMethod.setDescription(shippingMethod.getDescription());
        existingShippingMethod.setCoverageArea(shippingMethod.getCoverageArea());
        existingShippingMethod.setCourierName(shippingMethod.getCourierName());
        existingShippingMethod.setCost(shippingMethod.getCost());
        existingShippingMethod.setMinOrderAmount(shippingMethod.getMinOrderAmount());
        existingShippingMethod.setMaxWeightKg(shippingMethod.getMaxWeightKg());
        existingShippingMethod.setIsFreeShipping(shippingMethod.getIsFreeShipping());
        existingShippingMethod.setEstimatedDays(shippingMethod.getEstimatedDays());
        existingShippingMethod.setSortOrder(shippingMethod.getSortOrder());
        existingShippingMethod.setStatus(shippingMethod.getStatus());

        return entityManager.merge(existingShippingMethod);
    }

    public boolean deleteShippingMethod(Long id) {
        ShippingMethod shippingMethod = entityManager.find(ShippingMethod.class, id);
        if (shippingMethod == null) {
            return false;
        }

        entityManager.remove(shippingMethod);
        return true;
    }
}
