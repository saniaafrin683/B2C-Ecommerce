package com.styleora.controller;

import com.styleora.dto.AdminNotificationResponse;
import com.styleora.service.AdminNotificationService;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/notifications")
public class NotificationController {

    private final AdminNotificationService adminNotificationService;

    public NotificationController(AdminNotificationService adminNotificationService) {
        this.adminNotificationService = adminNotificationService;
    }

    @GetMapping("/admin")
    public AdminNotificationResponse getAdminNotifications() {
        return adminNotificationService.getAdminNotifications();
    }
}
