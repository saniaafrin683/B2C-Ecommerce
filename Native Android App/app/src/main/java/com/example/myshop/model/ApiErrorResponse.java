package com.example.myshop.model;

import java.util.Map;

public class ApiErrorResponse {
    private String message;
    private Map<String, String> validationErrors;

    public String getMessage() {
        return message;
    }

    public Map<String, String> getValidationErrors() {
        return validationErrors;
    }
}
