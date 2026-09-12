package com.example.myshop.storage;

import android.content.Context;
import android.content.SharedPreferences;

import com.example.myshop.model.AuthResponse;
import com.example.myshop.model.Customer;

public class SessionManager {
    private static final String PREFS_NAME = "myshop_session";
    private static final String KEY_TOKEN = "token";
    private static final String KEY_ROLE = "role";
    private static final String KEY_CUSTOMER_ID = "customer_id";
    private static final String KEY_CUSTOMER_NAME = "customer_name";
    private static final String KEY_CUSTOMER_EMAIL = "customer_email";
    private static final String KEY_CUSTOMER_CODE = "customer_code";

    private final SharedPreferences preferences;

    public SessionManager(Context context) {
        preferences = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE);
    }

    public void saveSession(AuthResponse response) {
        String token = response == null ? null : response.getToken();
        if (token == null || token.trim().isEmpty()) {
            clearSession();
            return;
        }

        SharedPreferences.Editor editor = preferences.edit().clear()
                .putString(KEY_TOKEN, token)
                .putString(KEY_ROLE, response.getRole());

        Customer customer = response.getCustomer();
        if (customer != null) {
            if (customer.getId() != null) {
                editor.putLong(KEY_CUSTOMER_ID, customer.getId());
            }
            editor.putString(KEY_CUSTOMER_NAME, customer.getFullName())
                    .putString(KEY_CUSTOMER_EMAIL, customer.getEmail())
                    .putString(KEY_CUSTOMER_CODE, customer.getCustomerCode());
        }
        editor.apply();
    }

    public boolean isLoggedIn() {
        String token = preferences.getString(KEY_TOKEN, null);
        return token != null && !token.trim().isEmpty();
    }

    public String getCustomerName() {
        return preferences.getString(KEY_CUSTOMER_NAME, "");
    }

    public String getCustomerEmail() {
        return preferences.getString(KEY_CUSTOMER_EMAIL, "");
    }

    public long getCustomerId() {
        return preferences.getLong(KEY_CUSTOMER_ID, -1L);
    }

    public String getToken() {
        return preferences.getString(KEY_TOKEN, "");
    }

    public void clearSession() {
        preferences.edit().clear().apply();
    }
}
