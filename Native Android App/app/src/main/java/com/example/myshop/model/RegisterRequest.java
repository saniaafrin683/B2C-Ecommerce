package com.example.myshop.model;

public class RegisterRequest {
    private final String fullName;
    private final String email;
    private final String password;
    private final String phone;
    private final String address;
    private final String city;
    private final String country;

    public RegisterRequest(
            String fullName,
            String email,
            String password,
            String phone,
            String address,
            String city,
            String country
    ) {
        this.fullName = fullName;
        this.email = email;
        this.password = password;
        this.phone = emptyToNull(phone);
        this.address = emptyToNull(address);
        this.city = emptyToNull(city);
        this.country = emptyToNull(country);
    }

    private String emptyToNull(String value) {
        return value == null || value.trim().isEmpty() ? null : value.trim();
    }
}
