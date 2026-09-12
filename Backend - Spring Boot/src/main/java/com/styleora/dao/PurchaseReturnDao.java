package com.styleora.dao;

import com.styleora.model.PurchaseReturn;
import jakarta.persistence.EntityManager;
import jakarta.persistence.PersistenceContext;
import jakarta.transaction.Transactional;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
@Transactional
public class PurchaseReturnDao {

    @PersistenceContext
    private EntityManager entityManager;

    public PurchaseReturn savePurchaseReturn(PurchaseReturn purchaseReturn) {
        entityManager.persist(purchaseReturn);
        return purchaseReturn;
    }

    public List<PurchaseReturn> getAllPurchaseReturns() {
        return entityManager
                .createQuery("from PurchaseReturn pr order by pr.id desc", PurchaseReturn.class)
                .getResultList();
    }

    public PurchaseReturn getPurchaseReturnById(Long id) {
        return entityManager.find(PurchaseReturn.class, id);
    }

    public PurchaseReturn updatePurchaseReturn(Long id, PurchaseReturn purchaseReturn) {
        PurchaseReturn existingPurchaseReturn = entityManager.find(PurchaseReturn.class, id);

        if (existingPurchaseReturn == null) {
            return null;
        }

        existingPurchaseReturn.setReturnId(purchaseReturn.getReturnId());
        existingPurchaseReturn.setPurchaseOrderId(purchaseReturn.getPurchaseOrderId());
        existingPurchaseReturn.setSupplierName(purchaseReturn.getSupplierName());
        existingPurchaseReturn.setSupplierEmail(purchaseReturn.getSupplierEmail());
        existingPurchaseReturn.setSupplierPhone(purchaseReturn.getSupplierPhone());
        existingPurchaseReturn.setReturnDate(purchaseReturn.getReturnDate());
        existingPurchaseReturn.setReturnReason(purchaseReturn.getReturnReason());
        existingPurchaseReturn.setReturnStatus(purchaseReturn.getReturnStatus());
        existingPurchaseReturn.setRefundStatus(purchaseReturn.getRefundStatus());
        existingPurchaseReturn.setPaymentMethod(purchaseReturn.getPaymentMethod());
        existingPurchaseReturn.setItems(purchaseReturn.getItems());
        existingPurchaseReturn.setSubtotal(purchaseReturn.getSubtotal());
        existingPurchaseReturn.setTax(purchaseReturn.getTax());
        existingPurchaseReturn.setDiscount(purchaseReturn.getDiscount());
        existingPurchaseReturn.setTotalAmount(purchaseReturn.getTotalAmount());
        existingPurchaseReturn.setNotes(purchaseReturn.getNotes());

        return existingPurchaseReturn;
    }

    public boolean deletePurchaseReturn(Long id) {
        PurchaseReturn purchaseReturn = entityManager.find(PurchaseReturn.class, id);
        if (purchaseReturn == null) {
            return false;
        }

        entityManager.remove(purchaseReturn);
        return true;
    }
}
