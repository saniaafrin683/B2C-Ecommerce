package com.example.myshop;

import android.app.Activity;
import android.content.Intent;
import android.os.Bundle;
import android.widget.TextView;
import android.widget.Toast;

import com.example.myshop.storage.SessionManager;

public class DashboardActivity extends Activity {
    private SessionManager sessionManager;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        ThemeManager.applyTheme(this);
        sessionManager = new SessionManager(this);

        if (!sessionManager.isLoggedIn()) {
            openLogin();
            return;
        }

        setContentView(R.layout.activity_dashboard);
        TextView welcomeText = findViewById(R.id.welcomeText);
        String name = sessionManager.getCustomerName();
        welcomeText.setText(name.isEmpty() ? "Welcome to MyShop" : "Welcome, " + name);

        findViewById(R.id.productsCard).setOnClickListener(view -> startActivity(new Intent(this, ProductActivity.class)));
        findViewById(R.id.categoriesCard).setOnClickListener(view -> startActivity(new Intent(this, CategoryActivity.class)));
        findViewById(R.id.hotDealsCard).setOnClickListener(view -> {
            Intent intent = new Intent(this, ProductActivity.class);
            intent.putExtra(ProductActivity.EXTRA_TITLE, "Hot Deals");
            intent.putExtra(ProductActivity.EXTRA_HOT_DEALS, true);
            startActivity(intent);
        });
        findViewById(R.id.wishlistCard).setOnClickListener(view -> startActivity(new Intent(this, WishlistActivity.class)));
        findViewById(R.id.cartCard).setOnClickListener(view -> startActivity(new Intent(this, CartActivity.class)));
        findViewById(R.id.ordersCard).setOnClickListener(view -> startActivity(new Intent(this, OrdersActivity.class)));
        findViewById(R.id.profileCard).setOnClickListener(view -> startActivity(new Intent(this, ProfileActivity.class)));
        findViewById(R.id.logoutCard).setOnClickListener(view -> logout());
    }

    private void showComingSoon(String feature) {
        Toast.makeText(this, feature + " screen will be added next.", Toast.LENGTH_SHORT).show();
    }

    private void showProfile() {
        String email = sessionManager.getCustomerEmail();
        String message = email.isEmpty() ? "Profile" : "Signed in as " + email;
        Toast.makeText(this, message, Toast.LENGTH_LONG).show();
    }

    private void logout() {
        sessionManager.clearSession();
        openLogin();
    }

    private void openLogin() {
        Intent intent = new Intent(this, LoginActivity.class);
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK | Intent.FLAG_ACTIVITY_CLEAR_TASK);
        startActivity(intent);
        finish();
    }
}
