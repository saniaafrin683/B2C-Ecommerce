package com.example.myshop.network;

import com.example.myshop.model.ApiErrorResponse;

import java.util.Map;

import okhttp3.ResponseBody;
import retrofit2.Response;

public final class ApiErrorParser {
    private ApiErrorParser() {
    }

    public static String getMessage(Response<?> response) {
        ResponseBody errorBody = response.errorBody();
        if (errorBody == null) {
            Object body = response.body();
            if (body instanceof com.example.myshop.model.AuthResponse) {
                String message = ((com.example.myshop.model.AuthResponse) body).getMessage();
                if (hasText(message)) {
                    return message;
                }
            }
            return "Request failed. Please try again.";
        }

        try {
            ApiErrorResponse error = RetrofitClient.getGson().fromJson(
                    errorBody.charStream(),
                    ApiErrorResponse.class
            );

            if (error != null && error.getValidationErrors() != null
                    && !error.getValidationErrors().isEmpty()) {
                Map.Entry<String, String> firstError =
                        error.getValidationErrors().entrySet().iterator().next();
                return firstError.getValue();
            }

            if (error != null && hasText(error.getMessage())) {
                return error.getMessage();
            }
        } catch (Exception ignored) {
            // The fallback below is used if the server returns an unexpected body.
        }

        return "Request failed. Please try again.";
    }

    private static boolean hasText(String value) {
        return value != null && !value.trim().isEmpty();
    }
}
