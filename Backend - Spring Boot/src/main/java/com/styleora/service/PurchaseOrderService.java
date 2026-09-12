package com.styleora.service;

import com.styleora.dao.PurchaseOrderDao;
import com.styleora.model.PurchaseOrder;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
public class PurchaseOrderService {

    private final PurchaseOrderDao purchaseOrderDao;

    public PurchaseOrderService(PurchaseOrderDao purchaseOrderDao) {
        this.purchaseOrderDao = purchaseOrderDao;
    }

    public PurchaseOrder createPurchaseOrder(PurchaseOrder purchaseOrder) {
        return purchaseOrderDao.savePurchaseOrder(purchaseOrder);
    }

    public List<PurchaseOrder> getAllPurchaseOrders() {
        return purchaseOrderDao.getAllPurchaseOrders();
    }

    public PurchaseOrder getPurchaseOrderById(Long id) {
        return purchaseOrderDao.getPurchaseOrderById(id);
    }

    public PurchaseOrder updatePurchaseOrder(Long id, PurchaseOrder purchaseOrder) {
        return purchaseOrderDao.updatePurchaseOrder(id, purchaseOrder);
    }

    public boolean deletePurchaseOrder(Long id) {
        return purchaseOrderDao.deletePurchaseOrder(id);
    }
}
