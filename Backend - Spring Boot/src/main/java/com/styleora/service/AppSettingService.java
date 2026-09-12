package com.styleora.service;

import com.styleora.dao.AppSettingDao;
import com.styleora.model.AppSetting;
import org.springframework.stereotype.Service;

import java.time.LocalDate;

@Service
public class AppSettingService {
    private static final String DEFAULT_CURRENCY = "BDT";

    private final AppSettingDao appSettingDao;

    public AppSettingService(AppSettingDao appSettingDao) {
        this.appSettingDao = appSettingDao;
    }

    public AppSetting saveSetting(AppSetting appSetting) {
        LocalDate today = LocalDate.now();
        sanitizeSetting(appSetting);
        if (appSetting.getCreatedAt() == null) {
            appSetting.setCreatedAt(today);
        }
        if (appSetting.getMaintenanceMode() == null) {
            appSetting.setMaintenanceMode(false);
        }
        appSetting.setUpdatedAt(today);
        return appSettingDao.saveSetting(appSetting);
    }

    public AppSetting getCurrentSetting() {
        AppSetting currentSetting = appSettingDao.getCurrentSetting();
        sanitizeSetting(currentSetting);
        return currentSetting;
    }

    public AppSetting updateSetting(Long id, AppSetting appSetting) {
        AppSetting existingSetting = appSettingDao.getSettingById(id);
        if (existingSetting == null) {
            return null;
        }

        sanitizeSetting(appSetting);
        appSetting.setCreatedAt(existingSetting.getCreatedAt());
        appSetting.setUpdatedAt(LocalDate.now());
        if (appSetting.getMaintenanceMode() == null) {
            appSetting.setMaintenanceMode(false);
        }
        return appSettingDao.updateSetting(id, appSetting);
    }

    public boolean deleteSetting(Long id) {
        return appSettingDao.deleteSetting(id);
    }

    private void sanitizeSetting(AppSetting appSetting) {
        if (appSetting == null) {
            return;
        }

        appSetting.setCurrency(sanitizeCurrency(appSetting.getCurrency()));
    }

    private String sanitizeCurrency(String currency) {
        if (currency == null) {
            return DEFAULT_CURRENCY;
        }

        String trimmed = currency.trim();
        if (trimmed.isEmpty()) {
            return DEFAULT_CURRENCY;
        }

        if (trimmed.contains("৳")) {
            return "৳";
        }

        String upper = trimmed.toUpperCase();
        StringBuilder letters = new StringBuilder();

        for (int i = 0; i < upper.length(); i++) {
            char current = upper.charAt(i);
            if (current >= 'A' && current <= 'Z') {
                letters.append(current);
                if (letters.length() == 3) {
                    return letters.toString();
                }
            } else if (letters.length() > 0) {
                break;
            }
        }

        return DEFAULT_CURRENCY;
    }
}
