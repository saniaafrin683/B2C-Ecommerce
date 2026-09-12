package com.styleora.dto;

import java.util.ArrayList;
import java.util.List;

public class AdminNotificationResponse {

    private List<AdminNotificationItem> notifications = new ArrayList<>();

    public AdminNotificationResponse() {
    }

    public AdminNotificationResponse(List<AdminNotificationItem> notifications) {
        this.notifications = notifications == null ? new ArrayList<>() : notifications;
    }

    public List<AdminNotificationItem> getNotifications() {
        return notifications;
    }

    public void setNotifications(List<AdminNotificationItem> notifications) {
        this.notifications = notifications == null ? new ArrayList<>() : notifications;
    }
}
