package com.example.myshop.model;

public class AuthResponse {
    private boolean success;
    private String message;
    private String token;
    private String role;
    private Customer customer;

    public boolean isSuccess() {
        return success;
    }

    public String getMessage() {
        return message;
    }

    public String getToken() {
        return token;
    }

    public String getRole() {
        return role;
    }

    public Customer getCustomer() {
        return customer;
    }
}
