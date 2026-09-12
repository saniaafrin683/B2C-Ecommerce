package com.styleora.service;

import com.styleora.dao.PurchaseReturnDao;
import com.styleora.model.PurchaseReturn;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
public class PurchaseReturnService {

    private final PurchaseReturnDao purchaseReturnDao;

    public PurchaseReturnService(PurchaseReturnDao purchaseReturnDao) {
        this.purchaseReturnDao = purchaseReturnDao;
    }

    public PurchaseReturn createPurchaseReturn(PurchaseReturn purchaseReturn) {
        return purchaseReturnDao.savePurchaseReturn(purchaseReturn);
    }

    public List<PurchaseReturn> getAllPurchaseReturns() {
        return purchaseReturnDao.getAllPurchaseReturns();
    }

    public PurchaseReturn getPurchaseReturnById(Long id) {
        return purchaseReturnDao.getPurchaseReturnById(id);
    }

    public PurchaseReturn updatePurchaseReturn(Long id, PurchaseReturn purchaseReturn) {
        return purchaseReturnDao.updatePurchaseReturn(id, purchaseReturn);
    }

    public boolean deletePurchaseReturn(Long id) {
        return purchaseReturnDao.deletePurchaseReturn(id);
    }
}
