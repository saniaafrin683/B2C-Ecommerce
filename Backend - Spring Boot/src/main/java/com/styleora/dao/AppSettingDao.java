package com.styleora.dao;

import com.styleora.model.AppSetting;
import jakarta.persistence.EntityManager;
import jakarta.persistence.PersistenceContext;
import jakarta.transaction.Transactional;
import org.springframework.stereotype.Repository;

@Repository
@Transactional
public class AppSettingDao {

    @PersistenceContext
    private EntityManager entityManager;

    public AppSetting saveSetting(AppSetting appSetting) {
        entityManager.persist(appSetting);
        return appSetting;
    }

    public AppSetting getCurrentSetting() {
        return entityManager
                .createQuery("from AppSetting a order by a.id desc", AppSetting.class)
                .setMaxResults(1)
                .getResultStream()
                .findFirst()
                .orElse(null);
    }

    public AppSetting getSettingById(Long id) {
        return entityManager.find(AppSetting.class, id);
    }

    public AppSetting updateSetting(Long id, AppSetting appSetting) {
        AppSetting existingSetting = entityManager.find(AppSetting.class, id);
        if (existingSetting == null) {
            return null;
        }

        existingSetting.setStoreName(appSetting.getStoreName());
        existingSetting.setStoreTagline(appSetting.getStoreTagline());
        existingSetting.setSupportEmail(appSetting.getSupportEmail());
        existingSetting.setSupportPhone(appSetting.getSupportPhone());
        existingSetting.setBusinessAddress(appSetting.getBusinessAddress());
        existingSetting.setCurrency(appSetting.getCurrency());
        existingSetting.setTaxRate(appSetting.getTaxRate());
        existingSetting.setShippingCharge(appSetting.getShippingCharge());
        existingSetting.setOrderPrefix(appSetting.getOrderPrefix());
        existingSetting.setInvoicePrefix(appSetting.getInvoicePrefix());
        existingSetting.setPaymentMethods(appSetting.getPaymentMethods());
        existingSetting.setLogoUrl(appSetting.getLogoUrl());
        existingSetting.setFaviconUrl(appSetting.getFaviconUrl());
        existingSetting.setMaintenanceMode(appSetting.getMaintenanceMode());
        existingSetting.setCreatedAt(appSetting.getCreatedAt());
        existingSetting.setUpdatedAt(appSetting.getUpdatedAt());

        return entityManager.merge(existingSetting);
    }

    public boolean deleteSetting(Long id) {
        AppSetting appSetting = entityManager.find(AppSetting.class, id);
        if (appSetting == null) {
            return false;
        }

        entityManager.remove(appSetting);
        return true;
    }
}
