package com.example.myshop;

import android.app.Activity;
import android.content.Intent;
import android.graphics.Typeface;
import android.os.Bundle;
import android.view.Gravity;
import android.view.View;
import android.widget.Button;
import android.widget.LinearLayout;
import android.widget.ProgressBar;
import android.widget.TextView;
import android.widget.Toast;

import com.example.myshop.model.OrderDetails;
import com.example.myshop.model.OrderItemRequest;
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

public class OrdersActivity extends Activity {
    private SessionManager sessionManager;
    private LinearLayout ordersContainer;
    private ProgressBar progressBar;
    private TextView emptyText;
    private Map<Long, ReturnRequest> returnRequestsByOrderId = new HashMap<>();

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
        setContentView(R.layout.activity_orders);
        findViewById(R.id.backButton).setOnClickListener(view -> finish());
        ordersContainer = findViewById(R.id.ordersContainer);
        progressBar = findViewById(R.id.ordersProgressBar);
        emptyText = findViewById(R.id.ordersEmptyText);
    }

    @Override
    protected void onResume() {
        super.onResume();
        loadOrders();
    }

    private void loadOrders() {
        progressBar.setVisibility(View.VISIBLE);
        emptyText.setVisibility(View.GONE);
        RetrofitClient.getApiService().getMyOrders("Bearer " + sessionManager.getToken()).enqueue(new Callback<List<OrderDetails>>() {
            @Override
            public void onResponse(Call<List<OrderDetails>> call, Response<List<OrderDetails>> response) {
                progressBar.setVisibility(View.GONE);
                if (!response.isSuccessful() || response.body() == null || response.body().isEmpty()) {
                    emptyText.setVisibility(View.VISIBLE);
                    return;
                }
                bindOrders(response.body());
                loadReturnStatuses(response.body());
            }

            @Override
            public void onFailure(Call<List<OrderDetails>> call, Throwable throwable) {
                progressBar.setVisibility(View.GONE);
                emptyText.setVisibility(View.VISIBLE);
                Toast.makeText(OrdersActivity.this, "Unable to load orders.", Toast.LENGTH_SHORT).show();
            }
        });
    }

    private void loadReturnStatuses(List<OrderDetails> orders) {
        long customerId = sessionManager.getCustomerId();
        if (customerId <= 0) {
            return;
        }

        RetrofitClient.getApiService()
                .getCustomerReturnRequests("Bearer " + sessionManager.getToken(), customerId)
                .enqueue(new Callback<List<ReturnRequest>>() {
                    @Override
                    public void onResponse(Call<List<ReturnRequest>> call, Response<List<ReturnRequest>> response) {
                        if (!response.isSuccessful() || response.body() == null) {
                            return;
                        }
                        Map<Long, ReturnRequest> mappedRequests = new HashMap<>();
                        for (ReturnRequest request : response.body()) {
                            if (request.getOrderId() != null) {
                                mappedRequests.put(request.getOrderId(), request);
                            }
                        }
                        returnRequestsByOrderId = mappedRequests;
                        bindOrders(orders);
                    }

                    @Override
                    public void onFailure(Call<List<ReturnRequest>> call, Throwable throwable) {
                        // Return status is supplementary; order history remains usable without it.
                    }
                });
    }

    private void bindOrders(List<OrderDetails> orders) {
        ordersContainer.removeAllViews();
        for (OrderDetails order : orders) {
            ordersContainer.addView(createOrderCard(order));
        }
    }

    private View createOrderCard(OrderDetails order) {
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
        card.addView(headerRow, new LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
        ));

        TextView orderIdText = createText(value(order.getOrderId(), "Order"), 17, R.color.text_primary, true);
        headerRow.addView(orderIdText, new LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.WRAP_CONTENT, 1));

        TextView statusText = createText(value(order.getOrderStatus(), "Pending"), 12, R.color.white, true);
        statusText.setGravity(Gravity.CENTER);
        statusText.setPadding(dp(10), dp(5), dp(10), dp(5));
        statusText.setBackgroundResource(R.drawable.bg_discount_badge);
        headerRow.addView(statusText);

        TextView totalText = createText(formatMoney(order.getTotalAmount()), 22, R.color.text_primary, true);
        LinearLayout.LayoutParams totalParams = new LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
        );
        totalParams.setMargins(0, dp(12), 0, 0);
        card.addView(totalText, totalParams);

        card.addView(createInfoRow("Order date", value(order.getCreatedAt(), "Not available")));
        card.addView(createInfoRow("Payment", value(order.getPaymentMethod(), "Not available")));
        card.addView(createInfoRow("Payment status", value(order.getPaymentStatus(), "Pending")));
        card.addView(createInfoRow("Shipping address", value(order.getShippingAddress(), "Not available")));

        Long databaseOrderId = order.getDatabaseId();
        ReturnRequest returnRequest = databaseOrderId == null ? null : returnRequestsByOrderId.get(databaseOrderId);
        if (returnRequest != null) {
            card.addView(createInfoRow("Return status", value(returnRequest.getStatus(), "Pending")));
        }

        if (order.getOrderItems() != null && !order.getOrderItems().isEmpty()) {
            TextView itemsTitle = createText("Products", 15, R.color.text_primary, true);
            LinearLayout.LayoutParams titleParams = new LinearLayout.LayoutParams(
                    LinearLayout.LayoutParams.MATCH_PARENT,
                    LinearLayout.LayoutParams.WRAP_CONTENT
            );
            titleParams.setMargins(0, dp(14), 0, dp(6));
            card.addView(itemsTitle, titleParams);

            for (OrderItemRequest item : order.getOrderItems()) {
                card.addView(createItemRow(item));
            }
        }

        Button trackButton = new Button(this);
        trackButton.setText("Track Order");
        trackButton.setTextColor(getColor(R.color.white));
        trackButton.setTextSize(14);
        trackButton.setTypeface(null, Typeface.BOLD);
        trackButton.setAllCaps(false);
        trackButton.setBackgroundResource(R.drawable.bg_primary_button);
        trackButton.setOnClickListener(view -> openOrderTracking(order));
        LinearLayout.LayoutParams buttonParams = new LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                dp(48)
        );
        buttonParams.setMargins(0, dp(16), 0, 0);
        card.addView(trackButton, buttonParams);

        if (databaseOrderId != null) {
            Button invoiceButton = new Button(this);
            invoiceButton.setText("View Invoice");
            invoiceButton.setTextColor(getColor(R.color.primary));
            invoiceButton.setTextSize(14);
            invoiceButton.setTypeface(null, Typeface.BOLD);
            invoiceButton.setAllCaps(false);
            invoiceButton.setBackgroundResource(R.drawable.bg_card);
            invoiceButton.setOnClickListener(view -> InvoiceOpener.open(this, sessionManager, databaseOrderId));
            LinearLayout.LayoutParams invoiceButtonParams = new LinearLayout.LayoutParams(
                    LinearLayout.LayoutParams.MATCH_PARENT,
                    dp(48)
            );
            invoiceButtonParams.setMargins(0, dp(10), 0, 0);
            card.addView(invoiceButton, invoiceButtonParams);
        }

        if (databaseOrderId != null && isDelivered(order)) {
            Button reviewButton = createSecondaryButton("Write Review");
            reviewButton.setOnClickListener(view -> openWriteReview(databaseOrderId));
            LinearLayout.LayoutParams reviewButtonParams = new LinearLayout.LayoutParams(
                    LinearLayout.LayoutParams.MATCH_PARENT,
                    dp(48)
            );
            reviewButtonParams.setMargins(0, dp(10), 0, 0);
            card.addView(reviewButton, reviewButtonParams);

            if (returnRequest == null) {
                Button returnButton = createSecondaryButton("Request Return");
                returnButton.setOnClickListener(view -> openReturnRequest(databaseOrderId));
                LinearLayout.LayoutParams returnButtonParams = new LinearLayout.LayoutParams(
                        LinearLayout.LayoutParams.MATCH_PARENT,
                        dp(48)
                );
                returnButtonParams.setMargins(0, dp(10), 0, 0);
                card.addView(returnButton, returnButtonParams);
            }
        }

        return card;
    }

    private Button createSecondaryButton(String text) {
        Button button = new Button(this);
        button.setText(text);
        button.setTextColor(getColor(R.color.primary));
        button.setTextSize(14);
        button.setTypeface(null, Typeface.BOLD);
        button.setAllCaps(false);
        button.setBackgroundResource(R.drawable.bg_card);
        return button;
    }

    private void openOrderTracking(OrderDetails order) {
        Intent intent = new Intent(this, OrderTrackingActivity.class);
        Long databaseOrderId = order.getDatabaseId();
        if (databaseOrderId != null) {
            intent.putExtra(OrderTrackingActivity.EXTRA_ORDER_DB_ID, databaseOrderId);
        }
        intent.putExtra(OrderTrackingActivity.EXTRA_ORDER_ID, value(order.getOrderId(), "Order"));
        intent.putExtra(OrderTrackingActivity.EXTRA_ORDER_DATE, value(order.getCreatedAt(), "Not available"));
        intent.putExtra(OrderTrackingActivity.EXTRA_PAYMENT_METHOD, value(order.getPaymentMethod(), "Not available"));
        intent.putExtra(OrderTrackingActivity.EXTRA_TOTAL_AMOUNT, order.getTotalAmount() == null ? 0.0 : order.getTotalAmount());
        intent.putExtra(OrderTrackingActivity.EXTRA_SHIPPING_ADDRESS, value(order.getShippingAddress(), "Not available"));
        intent.putExtra(OrderTrackingActivity.EXTRA_ORDER_STATUS, value(order.getOrderStatus(), "Pending"));
        startActivity(intent);
    }

    private void openWriteReview(long orderId) {
        Intent intent = new Intent(this, WriteReviewActivity.class);
        intent.putExtra(WriteReviewActivity.EXTRA_ORDER_DB_ID, orderId);
        startActivity(intent);
    }

    private void openReturnRequest(long orderId) {
        Intent intent = new Intent(this, ReturnRequestActivity.class);
        intent.putExtra(ReturnRequestActivity.EXTRA_ORDER_DB_ID, orderId);
        startActivity(intent);
    }

    private View createInfoRow(String label, String value) {
        LinearLayout row = new LinearLayout(this);
        row.setOrientation(LinearLayout.VERTICAL);
        LinearLayout.LayoutParams rowParams = new LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
        );
        rowParams.setMargins(0, dp(10), 0, 0);
        row.setLayoutParams(rowParams);

        TextView labelText = createText(label, 12, R.color.text_secondary, true);
        TextView valueText = createText(value, 15, R.color.text_primary, false);
        valueText.setPadding(0, dp(3), 0, 0);
        row.addView(labelText);
        row.addView(valueText);
        return row;
    }

    private View createItemRow(OrderItemRequest item) {
        LinearLayout row = new LinearLayout(this);
        row.setOrientation(LinearLayout.VERTICAL);
        row.setPadding(dp(12), dp(10), dp(12), dp(10));
        row.setBackgroundResource(R.drawable.bg_delivery_badge);
        LinearLayout.LayoutParams rowParams = new LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
        );
        rowParams.setMargins(0, dp(8), 0, 0);
        row.setLayoutParams(rowParams);

        String name = value(item.getProductName(), "Product");
        int quantity = item.getQuantity() == null ? 0 : item.getQuantity();
        row.addView(createText(name + " x" + quantity, 14, R.color.text_primary, true));

        StringBuilder meta = new StringBuilder();
        if (hasText(item.getSize())) {
            meta.append("Size: ").append(item.getSize().trim());
        }
        if (hasText(item.getColor())) {
            if (meta.length() > 0) {
                meta.append("  ");
            }
            meta.append("Color: ").append(item.getColor().trim());
        }
        if (item.getLineTotal() != null) {
            if (meta.length() > 0) {
                meta.append("  ");
            }
            meta.append("Total: ").append(formatMoney(item.getLineTotal()));
        }
        if (meta.length() > 0) {
            TextView metaText = createText(meta.toString(), 13, R.color.text_secondary, false);
            metaText.setPadding(0, dp(3), 0, 0);
            row.addView(metaText);
        }
        return row;
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
        return value == null || value.trim().isEmpty() ? fallback : value.trim();
    }

    private boolean hasText(String value) {
        return value != null && !value.trim().isEmpty();
    }

    private boolean isDelivered(OrderDetails order) {
        return isDeliveredStatus(order.getOrderStatus()) || isDeliveredStatus(order.getShipmentStatus());
    }

    private boolean isDeliveredStatus(String status) {
        return status != null && "delivered".equals(status.trim().toLowerCase(Locale.US).replace("_", " ").replace("-", " "));
    }

    private String formatMoney(Double value) {
        if (value == null) {
            return "$0.00";
        }
        return "$" + String.format(Locale.US, "%.2f", value);
    }

    private int dp(int value) {
        return (int) (value * getResources().getDisplayMetrics().density);
    }
}
