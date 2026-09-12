package com.styleora.dao;

import com.styleora.model.Purchase;
import jakarta.persistence.EntityManager;
import jakarta.persistence.LockModeType;
import jakarta.persistence.PersistenceContext;
import jakarta.transaction.Transactional;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
@Transactional
public class PurchaseDao {

    @PersistenceContext
    private EntityManager entityManager;

    public Purchase savePurchase(Purchase purchase) {
        if (purchase.getId() == null) {
            entityManager.persist(purchase);
            entityManager.flush();
            return purchase;
        }

        Purchase mergedPurchase = entityManager.merge(purchase);
        entityManager.flush();
        return mergedPurchase;
    }

    public List<Purchase> getAllPurchases() {
        return entityManager.createQuery(
                        "select distinct p from Purchase p " +
                                "left join fetch p.purchaseItems pi " +
                                "left join fetch pi.product " +
                                "order by p.id desc",
                        Purchase.class
                )
                .getResultList();
    }

    public Purchase getPurchaseById(Long id) {
        List<Purchase> purchases = entityManager.createQuery(
                        "select distinct p from Purchase p " +
                                "left join fetch p.purchaseItems pi " +
                                "left join fetch pi.product " +
                                "where p.id = :id",
                        Purchase.class
                )
                .setParameter("id", id)
                .setMaxResults(1)
                .getResultList();

        return purchases.isEmpty() ? null : purchases.get(0);
    }

    public Purchase getPurchaseByIdForUpdate(Long id) {
        List<Purchase> purchases = entityManager.createQuery(
                        "select distinct p from Purchase p " +
                                "left join fetch p.purchaseItems pi " +
                                "left join fetch pi.product " +
                                "where p.id = :id",
                        Purchase.class
                )
                .setParameter("id", id)
                .setLockMode(LockModeType.PESSIMISTIC_WRITE)
                .setMaxResults(1)
                .getResultList();

        return purchases.isEmpty() ? null : purchases.get(0);
    }

    public boolean deletePurchase(Purchase purchase) {
        Purchase managedPurchase = purchase;
        if (!entityManager.contains(purchase)) {
            managedPurchase = entityManager.merge(purchase);
        }

        entityManager.remove(managedPurchase);
        entityManager.flush();
        return true;
    }
}
