package com.styleora.dto;

public class AdminLoginResponse {

    private boolean success;
    private String message;
    private String email;
    private String adminEmail;
    private String token;
    private String role;

    public AdminLoginResponse() {
    }

    public AdminLoginResponse(boolean success, String message, String email, String adminEmail, String token, String role) {
        this.success = success;
        this.message = message;
        this.email = email;
        this.adminEmail = adminEmail;
        this.token = token;
        this.role = role;
    }

    public boolean isSuccess() {
        return success;
    }

    public void setSuccess(boolean success) {
        this.success = success;
    }

    public String getMessage() {
        return message;
    }

    public void setMessage(String message) {
        this.message = message;
    }

    public String getEmail() {
        return email;
    }

    public void setEmail(String email) {
        this.email = email;
    }

    public String getAdminEmail() {
        return adminEmail;
    }

    public void setAdminEmail(String adminEmail) {
        this.adminEmail = adminEmail;
    }

    public String getToken() {
        return token;
    }

    public void setToken(String token) {
        this.token = token;
    }

    public String getRole() {
        return role;
    }

    public void setRole(String role) {
        this.role = role;
    }
}
