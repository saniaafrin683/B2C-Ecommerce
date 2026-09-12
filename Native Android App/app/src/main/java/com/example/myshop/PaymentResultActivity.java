package com.example.myshop;

import android.app.Activity;
import android.content.Intent;
import android.net.Uri;
import android.os.Bundle;
import android.widget.Toast;

public class PaymentResultActivity extends Activity {
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        ThemeManager.applyTheme(this);

        Uri data = getIntent().getData();
        String status = data == null ? "" : data.getQueryParameter("status");
        String message;
        if ("success".equalsIgnoreCase(status)) {
            message = "Payment completed.";
        } else if ("cancelled".equalsIgnoreCase(status)) {
            message = "Payment cancelled.";
        } else {
            message = "Payment was not completed.";
        }

        Toast.makeText(this, message, Toast.LENGTH_LONG).show();
        Intent intent = new Intent(this, OrdersActivity.class);
        intent.addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP | Intent.FLAG_ACTIVITY_NEW_TASK);
        startActivity(intent);
        finish();
    }
}
