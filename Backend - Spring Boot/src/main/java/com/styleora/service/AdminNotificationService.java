package com.styleora.service;

import com.styleora.dao.AdminNotificationDao;
import com.styleora.dto.AdminNotificationResponse;
import org.springframework.stereotype.Service;

@Service
public class AdminNotificationService {

    private final AdminNotificationDao adminNotificationDao;

    public AdminNotificationService(AdminNotificationDao adminNotificationDao) {
        this.adminNotificationDao = adminNotificationDao;
    }

    public AdminNotificationResponse getAdminNotifications() {
        return new AdminNotificationResponse(adminNotificationDao.getAdminNotifications());
    }
}
