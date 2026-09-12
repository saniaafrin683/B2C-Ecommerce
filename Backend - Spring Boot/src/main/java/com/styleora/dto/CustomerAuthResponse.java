package com.styleora.dto;

public class CustomerAuthResponse {

    private boolean success;
    private String message;
    private String token;
    private String role;
    private CustomerProfileResponse customer;

    public CustomerAuthResponse() {
    }

    public CustomerAuthResponse(boolean success, String message, String token, String role, CustomerProfileResponse customer) {
        this.success = success;
        this.message = message;
        this.token = token;
        this.role = role;
        this.customer = customer;
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

    public CustomerProfileResponse getCustomer() {
        return customer;
    }

    public void setCustomer(CustomerProfileResponse customer) {
        this.customer = customer;
    }
}
