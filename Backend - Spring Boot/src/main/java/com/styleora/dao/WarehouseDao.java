package com.styleora.dao;

import java.util.List;

import jakarta.persistence.EntityManager;
import jakarta.persistence.PersistenceContext;
import jakarta.transaction.Transactional;

import org.springframework.stereotype.Repository;

import com.styleora.model.Warehouse;

@Repository
@Transactional
public class WarehouseDao {

    @PersistenceContext
    private EntityManager entityManager;

    public void saveWarehouse(Warehouse warehouse) {

        entityManager.persist(warehouse);
    }

    public List<Warehouse> getAllWarehouses() {

        return entityManager
                .createQuery("from Warehouse", Warehouse.class)
                .getResultList();
    }

    public Warehouse getWarehouseById(Long id) {

        return entityManager.find(Warehouse.class, id);
    }

    public Warehouse getWarehouseByIdForUpdate(Long id) {
        return entityManager.find(Warehouse.class, id, jakarta.persistence.LockModeType.PESSIMISTIC_WRITE);
    }

    public void updateWarehouse(Warehouse warehouse) {
        if (warehouse.getId() == null) {
            return;
        }

        Warehouse existingWarehouse = entityManager.find(Warehouse.class, warehouse.getId());
        if (existingWarehouse == null) {
            return;
        }

        existingWarehouse.setWarehouseId(warehouse.getWarehouseId());
        existingWarehouse.setWarehouseName(warehouse.getWarehouseName());
        existingWarehouse.setLocation(warehouse.getLocation());
        existingWarehouse.setManager(warehouse.getManager());
        existingWarehouse.setContactNumber(warehouse.getContactNumber());
        existingWarehouse.setStockAvailable(warehouse.getStockAvailable());
        existingWarehouse.setStockShipping(warehouse.getStockShipping());
        existingWarehouse.setWarehouseRevenue(warehouse.getWarehouseRevenue());
    }

    public void deleteWarehouse(Long id) {

        Warehouse warehouse = entityManager.find(Warehouse.class, id);

        if (warehouse != null) {

            entityManager.remove(warehouse);
        }
    }

    public boolean increaseStockAvailable(Long id, int quantity) {
        if (id == null || quantity <= 0) {
            return false;
        }

        int updatedRows = entityManager.createQuery(
                        "UPDATE Warehouse w SET w.stockAvailable = COALESCE(w.stockAvailable, 0) + :quantity WHERE w.id = :warehouseId")
                .setParameter("warehouseId", id)
                .setParameter("quantity", quantity)
                .executeUpdate();

        return updatedRows > 0;
    }
}
