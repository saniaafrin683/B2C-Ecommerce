package com.example.myshop;

import android.app.Activity;
import android.content.Intent;
import android.graphics.Color;
import android.graphics.Typeface;
import android.graphics.drawable.GradientDrawable;
import android.os.Bundle;
import android.view.Gravity;
import android.view.View;
import android.widget.LinearLayout;
import android.widget.ProgressBar;
import android.widget.TextView;
import android.widget.Toast;

import com.example.myshop.model.Product;
import com.example.myshop.model.ReturnRequest;
import com.example.myshop.network.RetrofitClient;
import com.example.myshop.storage.SessionManager;

import java.util.HashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;

import retrofit2.Call;
import retrofit2.Callback;
import retrofit2.Response;

public class ReturnHistoryActivity extends Activity {
    private static final int STATUS_PENDING = Color.rgb(245, 124, 0);
    private static final int STATUS_APPROVED = Color.rgb(46, 125, 50);
    private static final int STATUS_REJECTED = Color.rgb(198, 40, 40);
    private static final int STATUS_COMPLETED = Color.rgb(21, 101, 192);

    private SessionManager sessionManager;
    private ProgressBar progressBar;
    private TextView emptyText;
    private LinearLayout returnsContainer;
    private List<ReturnRequest> currentRequests;
    private final Map<Long, String> productNames = new HashMap<>();

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

        setContentView(R.layout.activity_return_history);
        findViewById(R.id.backButton).setOnClickListener(view -> finish());
        progressBar = findViewById(R.id.returnHistoryProgressBar);
        emptyText = findViewById(R.id.returnHistoryEmptyText);
        returnsContainer = findViewById(R.id.returnHistoryContainer);
        loadReturns();
    }

    private void loadReturns() {
        long customerId = sessionManager.getCustomerId();
        if (customerId <= 0) {
            showEmpty("Return history is unavailable for this session.");
            return;
        }

        progressBar.setVisibility(View.VISIBLE);
        emptyText.setVisibility(View.GONE);
        returnsContainer.removeAllViews();

        RetrofitClient.getApiService()
                .getCustomerReturnRequests("Bearer " + sessionManager.getToken(), customerId)
                .enqueue(new Callback<List<ReturnRequest>>() {
                    @Override
                    public void onResponse(Call<List<ReturnRequest>> call, Response<List<ReturnRequest>> response) {
                        progressBar.setVisibility(View.GONE);
                        if (!response.isSuccessful() || response.body() == null || response.body().isEmpty()) {
                            showEmpty("No return requests found.");
                            return;
                        }
                        currentRequests = response.body();
                        bindReturns();
                        loadProductNames(currentRequests);
                    }

                    @Override
                    public void onFailure(Call<List<ReturnRequest>> call, Throwable throwable) {
                        progressBar.setVisibility(View.GONE);
                        showEmpty("Unable to load return requests.");
                        Toast.makeText(ReturnHistoryActivity.this, "Unable to load return requests.", Toast.LENGTH_SHORT).show();
                    }
                });
    }

    private void loadProductNames(List<ReturnRequest> requests) {
        for (ReturnRequest request : requests) {
            Long productId = request.getProductId();
            if (productId == null || productNames.containsKey(productId)) {
                continue;
            }

            RetrofitClient.getApiService().getProduct(productId).enqueue(new Callback<Product>() {
                @Override
                public void onResponse(Call<Product> call, Response<Product> response) {
                    if (response.isSuccessful() && response.body() != null && hasText(response.body().getName())) {
                        productNames.put(productId, response.body().getName().trim());
                        bindReturns();
                    }
                }

                @Override
                public void onFailure(Call<Product> call, Throwable throwable) {
                    // Product name lookup is best-effort; the product id fallback remains visible.
                }
            });
        }
    }

    private void bindReturns() {
        returnsContainer.removeAllViews();
        if (currentRequests == null || currentRequests.isEmpty()) {
            showEmpty("No return requests found.");
            return;
        }

        emptyText.setVisibility(View.GONE);
        for (ReturnRequest request : currentRequests) {
            returnsContainer.addView(createReturnCard(request));
        }
    }

    private View createReturnCard(ReturnRequest request) {
        LinearLayout card = new LinearLayout(this);
        card.setOrientation(LinearLayout.VERTICAL);
        card.setPadding(dp(16), dp(16), dp(16), dp(16));
        card.setBackgroundResource(R.drawable.bg_card);

        LinearLayout.LayoutParams cardParams = new LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
        );
        cardParams.setMargins(0, 0, 0, dp(14));
        card.setLayoutParams(cardParams);

        LinearLayout headerRow = new LinearLayout(this);
        headerRow.setOrientation(LinearLayout.HORIZONTAL);
        headerRow.setGravity(Gravity.CENTER_VERTICAL);
        card.addView(headerRow);

        TextView returnIdText = createText(returnId(request), 17, R.color.text_primary, true);
        headerRow.addView(returnIdText, new LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.WRAP_CONTENT, 1));

        TextView statusBadge = createText(displayStatus(request.getStatus()), 12, R.color.white, true);
        statusBadge.setGravity(Gravity.CENTER);
        statusBadge.setPadding(dp(10), dp(5), dp(10), dp(5));
        statusBadge.setBackground(statusBackground(request.getStatus()));
        headerRow.addView(statusBadge);

        card.addView(createInfoRow("Product", productName(request)));
        card.addView(createInfoRow("Reason", value(request.getReason(), "Not available")));
        card.addView(createInfoRow("Requested date", formatDate(request.getRequestedAt())));
        return card;
    }

    private View createInfoRow(String label, String value) {
        LinearLayout row = new LinearLayout(this);
        row.setOrientation(LinearLayout.VERTICAL);
        LinearLayout.LayoutParams rowParams = new LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
        );
        rowParams.setMargins(0, dp(12), 0, 0);
        row.setLayoutParams(rowParams);

        TextView labelText = createText(label, 12, R.color.text_secondary, true);
        TextView valueText = createText(value, 15, R.color.text_primary, false);
        valueText.setPadding(0, dp(3), 0, 0);
        row.addView(labelText);
        row.addView(valueText);
        return row;
    }

    private GradientDrawable statusBackground(String status) {
        GradientDrawable drawable = new GradientDrawable();
        drawable.setColor(statusColor(status));
        drawable.setCornerRadius(dp(14));
        return drawable;
    }

    private int statusColor(String status) {
        String normalized = normalizeStatus(status);
        if ("approved".equals(normalized)) {
            return STATUS_APPROVED;
        }
        if ("rejected".equals(normalized)) {
            return STATUS_REJECTED;
        }
        if ("completed".equals(normalized) || "refunded".equals(normalized)) {
            return STATUS_COMPLETED;
        }
        return STATUS_PENDING;
    }

    private String displayStatus(String status) {
        String normalized = normalizeStatus(status);
        if ("approved".equals(normalized)) {
            return "Approved";
        }
        if ("rejected".equals(normalized)) {
            return "Rejected";
        }
        if ("completed".equals(normalized) || "refunded".equals(normalized)) {
            return "Completed";
        }
        return "Pending";
    }

    private String normalizeStatus(String status) {
        return status == null ? "" : status.trim().toLowerCase(Locale.US).replace("_", " ").replace("-", " ");
    }

    private String productName(ReturnRequest request) {
        Long productId = request.getProductId();
        if (productId == null) {
            return "Product";
        }
        String name = productNames.get(productId);
        return hasText(name) ? name : "Product #" + productId;
    }

    private String returnId(ReturnRequest request) {
        if (request.getId() != null) {
            return "Return #" + request.getId();
        }
        if (hasText(request.getOrderReference())) {
            return "Return for " + request.getOrderReference();
        }
        return "Return request";
    }

    private String formatDate(String value) {
        if (!hasText(value)) {
            return "Not available";
        }
        String trimmed = value.trim();
        int separator = trimmed.indexOf('T');
        return separator > 0 ? trimmed.substring(0, separator) : trimmed;
    }

    private void showEmpty(String message) {
        returnsContainer.removeAllViews();
        emptyText.setText(message);
        emptyText.setVisibility(View.VISIBLE);
    }

    private TextView createText(String text, int sp, int colorRes, boolean bold) {
        TextView textView = new TextView(this);
        textView.setText(text);
        textView.setTextSize(sp);
        textView.setTextColor(getColor(colorRes));
        textView.setLineSpacing(dp(2), 1.0f);
        if (bold) {
            textView.setTypeface(null, Typeface.BOLD);
        }
        return textView;
    }

    private String value(String value, String fallback) {
        return hasText(value) ? value.trim() : fallback;
    }

    private boolean hasText(String value) {
        return value != null && !value.trim().isEmpty();
    }

    private int dp(int value) {
        return (int) (value * getResources().getDisplayMetrics().density);
    }
}
