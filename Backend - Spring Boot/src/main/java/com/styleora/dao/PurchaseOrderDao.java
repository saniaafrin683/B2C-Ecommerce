package com.styleora.dao;

import com.styleora.model.PurchaseOrder;
import jakarta.persistence.EntityManager;
import jakarta.persistence.PersistenceContext;
import jakarta.transaction.Transactional;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
@Transactional
public class PurchaseOrderDao {

    @PersistenceContext
    private EntityManager entityManager;

    public PurchaseOrder savePurchaseOrder(PurchaseOrder purchaseOrder) {
        entityManager.persist(purchaseOrder);
        return purchaseOrder;
    }

    public List<PurchaseOrder> getAllPurchaseOrders() {
        return entityManager
                .createQuery("from PurchaseOrder po order by po.id desc", PurchaseOrder.class)
                .getResultList();
    }

    public PurchaseOrder getPurchaseOrderById(Long id) {
        return entityManager.find(PurchaseOrder.class, id);
    }

    public PurchaseOrder updatePurchaseOrder(Long id, PurchaseOrder purchaseOrder) {
        PurchaseOrder existingPurchaseOrder = entityManager.find(PurchaseOrder.class, id);

        if (existingPurchaseOrder == null) {
            return null;
        }

        existingPurchaseOrder.setPurchaseOrderId(purchaseOrder.getPurchaseOrderId());
        existingPurchaseOrder.setSupplierName(purchaseOrder.getSupplierName());
        existingPurchaseOrder.setSupplierEmail(purchaseOrder.getSupplierEmail());
        existingPurchaseOrder.setSupplierPhone(purchaseOrder.getSupplierPhone());
        existingPurchaseOrder.setSupplierAddress(purchaseOrder.getSupplierAddress());
        existingPurchaseOrder.setOrderDate(purchaseOrder.getOrderDate());
        existingPurchaseOrder.setExpectedDeliveryDate(purchaseOrder.getExpectedDeliveryDate());
        existingPurchaseOrder.setOrderStatus(purchaseOrder.getOrderStatus());
        existingPurchaseOrder.setPaymentStatus(purchaseOrder.getPaymentStatus());
        existingPurchaseOrder.setPaymentMethod(purchaseOrder.getPaymentMethod());
        existingPurchaseOrder.setItems(purchaseOrder.getItems());
        existingPurchaseOrder.setSubtotal(purchaseOrder.getSubtotal());
        existingPurchaseOrder.setDiscount(purchaseOrder.getDiscount());
        existingPurchaseOrder.setTax(purchaseOrder.getTax());
        existingPurchaseOrder.setShippingCost(purchaseOrder.getShippingCost());
        existingPurchaseOrder.setTotalAmount(purchaseOrder.getTotalAmount());
        existingPurchaseOrder.setPaidAmount(purchaseOrder.getPaidAmount());
        existingPurchaseOrder.setDueAmount(purchaseOrder.getDueAmount());
        existingPurchaseOrder.setNotes(purchaseOrder.getNotes());

        return existingPurchaseOrder;
    }

    public boolean deletePurchaseOrder(Long id) {
        PurchaseOrder purchaseOrder = entityManager.find(PurchaseOrder.class, id);
        if (purchaseOrder == null) {
            return false;
        }

        entityManager.remove(purchaseOrder);
        return true;
    }
}
