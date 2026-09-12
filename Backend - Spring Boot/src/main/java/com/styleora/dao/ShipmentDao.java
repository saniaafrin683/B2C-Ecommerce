package com.styleora.dao;

import com.styleora.model.Shipment;
import jakarta.persistence.EntityManager;
import jakarta.persistence.LockModeType;
import jakarta.persistence.PersistenceContext;
import jakarta.transaction.Transactional;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
@Transactional
public class ShipmentDao {

    @PersistenceContext
    private EntityManager entityManager;

    public Shipment saveShipment(Shipment shipment) {
        shipment.setId(null);
        entityManager.persist(shipment);
        entityManager.flush();
        return shipment;
    }

    public List<Shipment> getAllShipments() {
        return entityManager
                .createQuery("from Shipment s order by s.id desc", Shipment.class)
                .getResultList();
    }

    public Shipment getShipmentById(Long id) {
        return entityManager.find(Shipment.class, id);
    }

    public Shipment getShipmentByIdForUpdate(Long id) {
        return entityManager.find(Shipment.class, id, LockModeType.PESSIMISTIC_WRITE);
    }

    public Shipment getLatestShipmentByOrderId(Long orderId) {
        List<Shipment> shipments = entityManager.createQuery(
                "select s from Shipment s where s.orderId = :orderId " +
                        "order by case when s.estimatedDeliveryDate is null then 1 else 0 end, s.estimatedDeliveryDate desc, " +
                        "case when s.dispatchDate is null then 1 else 0 end, s.dispatchDate desc, s.id desc",
                Shipment.class
        ).setParameter("orderId", orderId)
         .setMaxResults(1)
         .getResultList();

        return shipments.isEmpty() ? null : shipments.get(0);
    }

    public List<Shipment> getShipmentsByOrderId(Long orderId) {
        return entityManager.createQuery(
                "select s from Shipment s where s.orderId = :orderId " +
                        "order by case when s.dispatchDate is null then 1 else 0 end, s.dispatchDate desc, s.id desc",
                Shipment.class
        ).setParameter("orderId", orderId)
         .getResultList();
    }

    public Shipment updateShipment(Long id, Shipment shipment) {
        Shipment existingShipment = entityManager.find(Shipment.class, id);
        if (existingShipment == null) {
            return null;
        }

        existingShipment.setOrderId(shipment.getOrderId());
        existingShipment.setShippingMethodId(shipment.getShippingMethodId());
        existingShipment.setTrackingNumber(shipment.getTrackingNumber());
        existingShipment.setCourierName(shipment.getCourierName());
        existingShipment.setStatus(shipment.getStatus());
        existingShipment.setDispatchDate(shipment.getDispatchDate());
        existingShipment.setEstimatedDeliveryDate(shipment.getEstimatedDeliveryDate());
        existingShipment.setDeliveredDate(shipment.getDeliveredDate());
        existingShipment.setRemarks(shipment.getRemarks());

        entityManager.flush();
        return existingShipment;
    }

    public boolean deleteShipment(Long id) {
        Shipment shipment = entityManager.find(Shipment.class, id);
        if (shipment == null) {
            return false;
        }

        entityManager.remove(shipment);
        entityManager.flush();
        return true;
    }

    public int deleteShipmentsByOrderId(Long orderId) {
        int deleted = entityManager.createQuery("delete from Shipment s where s.orderId = :orderId")
                .setParameter("orderId", orderId)
                .executeUpdate();
        entityManager.flush();
        return deleted;
    }
}
