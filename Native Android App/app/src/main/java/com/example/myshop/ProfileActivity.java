package com.example.myshop;

import android.app.Activity;
import android.content.Intent;
import android.os.Bundle;
import android.view.View;
import android.widget.Switch;
import android.widget.TextView;
import android.widget.Toast;

import com.example.myshop.model.Customer;
import com.example.myshop.network.RetrofitClient;
import com.example.myshop.storage.SessionManager;

import retrofit2.Call;
import retrofit2.Callback;
import retrofit2.Response;

public class ProfileActivity extends Activity {
    private SessionManager sessionManager;
    private TextView profileNameText;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        ThemeManager.applyTheme(this);
        sessionManager = new SessionManager(this);
        if (!sessionManager.isLoggedIn()) {
            startActivity(new Intent(this, LoginActivity.class));
            finish();
            return;
        }
        setContentView(R.layout.activity_profile);
        profileNameText = findViewById(R.id.profileNameText);
        bindMenuActions();
        loadProfile();
    }

    private void bindMenuActions() {
        Switch darkModeSwitch = findViewById(R.id.darkModeSwitch);
        darkModeSwitch.setChecked(ThemeManager.isDarkMode(this));
        darkModeSwitch.setOnCheckedChangeListener((buttonView, isChecked) -> ThemeManager.setDarkMode(this, isChecked));

        findViewById(R.id.profileMyProfileRow).setOnClickListener(view -> Toast.makeText(this, "Profile editing will be added next.", Toast.LENGTH_SHORT).show());
        findViewById(R.id.profileAddressRow).setOnClickListener(view -> Toast.makeText(this, "Address book will be added next.", Toast.LENGTH_SHORT).show());
        findViewById(R.id.profileOrdersRow).setOnClickListener(view -> startActivity(new Intent(this, OrdersActivity.class)));
        findViewById(R.id.profileReturnsRow).setOnClickListener(view -> startActivity(new Intent(this, ReturnHistoryActivity.class)));
        findViewById(R.id.profileWishlistRow).setOnClickListener(view -> startActivity(new Intent(this, WishlistActivity.class)));
        findViewById(R.id.profileNotificationsRow).setOnClickListener(view -> startActivity(new Intent(this, NotificationActivity.class)));

        findViewById(R.id.termsConditionsRow).setOnClickListener(view -> showPolicyToast());
        findViewById(R.id.returnPolicyRow).setOnClickListener(view -> showPolicyToast());
        findViewById(R.id.privacyPolicyRow).setOnClickListener(view -> showPolicyToast());
        findViewById(R.id.shippingDeliveryRow).setOnClickListener(view -> showPolicyToast());
        findViewById(R.id.dataDeletionRow).setOnClickListener(view -> showPolicyToast());
        findViewById(R.id.logoutRow).setOnClickListener(view -> logout());

        findViewById(R.id.navHome).setOnClickListener(view -> startActivity(new Intent(this, HomeActivity.class)));
        findViewById(R.id.navBrands).setOnClickListener(view -> {
            Intent intent = new Intent(this, ProductActivity.class);
            intent.putExtra(ProductActivity.EXTRA_TITLE, "Brands");
            startActivity(intent);
        });
        findViewById(R.id.navCategories).setOnClickListener(view -> startActivity(new Intent(this, CategoryActivity.class)));
        findViewById(R.id.navBlog).setOnClickListener(view -> startActivity(new Intent(this, BlogActivity.class)));
    }

    private void loadProfile() {
        findViewById(R.id.profileProgressBar).setVisibility(View.VISIBLE);
        RetrofitClient.getApiService().getProfile("Bearer " + sessionManager.getToken()).enqueue(new Callback<Customer>() {
            @Override
            public void onResponse(Call<Customer> call, Response<Customer> response) {
                findViewById(R.id.profileProgressBar).setVisibility(View.GONE);
                if (!response.isSuccessful() || response.body() == null) {
                    showFallback();
                    return;
                }
                Customer customer = response.body();
                profileNameText.setText(displayName(customer.getFullName()));
            }

            @Override
            public void onFailure(Call<Customer> call, Throwable throwable) {
                findViewById(R.id.profileProgressBar).setVisibility(View.GONE);
                showFallback();
            }
        });
    }

    private void showFallback() {
        profileNameText.setText(displayName(sessionManager.getCustomerName()));
        Toast.makeText(this, "Showing saved profile.", Toast.LENGTH_SHORT).show();
    }

    private String displayName(String value) {
        if (value == null || value.trim().isEmpty()) {
            return "Customer";
        }
        return value.trim();
    }

    private void showPolicyToast() {
        Toast.makeText(this, "Policy pages will be added next.", Toast.LENGTH_SHORT).show();
    }

    private void logout() {
        sessionManager.clearSession();
        Intent intent = new Intent(this, LoginActivity.class);
        intent.setFlags(Intent.FLAG_ACTIVITY_NEW_TASK | Intent.FLAG_ACTIVITY_CLEAR_TASK);
        startActivity(intent);
    }
}
