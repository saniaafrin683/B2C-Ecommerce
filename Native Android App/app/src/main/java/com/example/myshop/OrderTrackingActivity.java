package com.example.myshop;

import android.app.Activity;
import android.graphics.Typeface;
import android.os.Bundle;
import android.view.Gravity;
import android.view.View;
import android.widget.LinearLayout;
import android.widget.ProgressBar;
import android.widget.TextView;
import android.widget.Toast;
import android.widget.Button;

import com.example.myshop.model.OrderDetails;
import com.example.myshop.network.RetrofitClient;
import com.example.myshop.storage.SessionManager;

import java.util.Locale;

import retrofit2.Call;
import retrofit2.Callback;
import retrofit2.Response;

public class OrderTrackingActivity extends Activity {
    public static final String EXTRA_ORDER_DB_ID = "order_db_id";
    public static final String EXTRA_ORDER_ID = "order_id";
    public static final String EXTRA_ORDER_DATE = "order_date";
    public static final String EXTRA_PAYMENT_METHOD = "payment_method";
    public static final String EXTRA_TOTAL_AMOUNT = "total_amount";
    public static final String EXTRA_SHIPPING_ADDRESS = "shipping_address";
    public static final String EXTRA_ORDER_STATUS = "order_status";

    private static final String[] TIMELINE_STATUSES = {
            "Pending",
            "Confirmed",
            "Processing",
            "Shipped",
            "Delivered",
            "Cancelled"
    };

    private SessionManager sessionManager;
    private ProgressBar progressBar;
    private TextView orderIdText;
    private TextView dateText;
    private TextView paymentText;
    private TextView totalText;
    private TextView addressText;
    private TextView statusText;
    private LinearLayout timelineContainer;
    private Button invoiceButton;

    private long orderDbId;
    private String orderId;
    private String orderDate;
    private String paymentMethod;
    private double totalAmount;
    private String shippingAddress;
    private String orderStatus;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        ThemeManager.applyTheme(this);
        sessionManager = new SessionManager(this);
        setContentView(R.layout.activity_order_tracking);

        findViewById(R.id.backButton).setOnClickListener(view -> finish());
        progressBar = findViewById(R.id.trackingProgressBar);
        orderIdText = findViewById(R.id.trackingOrderIdText);
        dateText = findViewById(R.id.trackingDateText);
        paymentText = findViewById(R.id.trackingPaymentText);
        totalText = findViewById(R.id.trackingTotalText);
        addressText = findViewById(R.id.trackingAddressText);
        statusText = findViewById(R.id.trackingStatusText);
        timelineContainer = findViewById(R.id.trackingTimelineContainer);
        invoiceButton = findViewById(R.id.trackingInvoiceButton);
        invoiceButton.setOnClickListener(view -> InvoiceOpener.open(this, sessionManager, orderDbId));

        readIntentData();
        bindOrderData();
        loadLatestOrderIfAvailable();
    }

    private void readIntentData() {
        orderDbId = getIntent().getLongExtra(EXTRA_ORDER_DB_ID, -1);
        orderId = getIntent().getStringExtra(EXTRA_ORDER_ID);
        orderDate = getIntent().getStringExtra(EXTRA_ORDER_DATE);
        paymentMethod = getIntent().getStringExtra(EXTRA_PAYMENT_METHOD);
        totalAmount = getIntent().getDoubleExtra(EXTRA_TOTAL_AMOUNT, 0.0);
        shippingAddress = getIntent().getStringExtra(EXTRA_SHIPPING_ADDRESS);
        orderStatus = getIntent().getStringExtra(EXTRA_ORDER_STATUS);
    }

    private void loadLatestOrderIfAvailable() {
        if (orderDbId <= 0 || !sessionManager.isLoggedIn()) {
            return;
        }

        progressBar.setVisibility(View.VISIBLE);
        RetrofitClient.getApiService()
                .getMyOrderById("Bearer " + sessionManager.getToken(), orderDbId)
                .enqueue(new Callback<OrderDetails>() {
                    @Override
                    public void onResponse(Call<OrderDetails> call, Response<OrderDetails> response) {
                        progressBar.setVisibility(View.GONE);
                        if (response.isSuccessful() && response.body() != null) {
                            applyOrderDetails(response.body());
                            bindOrderData();
                        }
                    }

                    @Override
                    public void onFailure(Call<OrderDetails> call, Throwable throwable) {
                        progressBar.setVisibility(View.GONE);
                        Toast.makeText(OrderTrackingActivity.this, "Showing saved order status.", Toast.LENGTH_SHORT).show();
                    }
                });
    }

    private void applyOrderDetails(OrderDetails order) {
        orderId = value(order.getOrderId(), orderId);
        orderDate = value(order.getCreatedAt(), orderDate);
        paymentMethod = value(order.getPaymentMethod(), paymentMethod);
        if (order.getTotalAmount() != null) {
            totalAmount = order.getTotalAmount();
        }
        shippingAddress = value(order.getShippingAddress(), shippingAddress);
        orderStatus = value(order.getShipmentStatus(), value(order.getOrderStatus(), orderStatus));
    }

    private void bindOrderData() {
        orderIdText.setText(value(orderId, "Order"));
        dateText.setText(value(orderDate, "Not available"));
        paymentText.setText(value(paymentMethod, "Not available"));
        totalText.setText(formatMoney(totalAmount));
        addressText.setText(value(shippingAddress, "Not available"));
        statusText.setText(formatDisplayStatus(orderStatus));
        renderTimeline(orderStatus);
        invoiceButton.setVisibility(orderDbId > 0 ? View.VISIBLE : View.GONE);
    }

    private void renderTimeline(String status) {
        timelineContainer.removeAllViews();
        int currentIndex = resolveStatusIndex(status);
        String normalized = normalizeStatus(status);
        boolean cancelled = "cancelled".equals(normalized) || "canceled".equals(normalized);

        for (int i = 0; i < TIMELINE_STATUSES.length; i++) {
            String label = TIMELINE_STATUSES[i];
            boolean isCurrent = i == currentIndex;
            boolean isComplete = !cancelled && i <= currentIndex && i < TIMELINE_STATUSES.length - 1;
            boolean isCancelledCurrent = cancelled && isCurrent;
            timelineContainer.addView(createTimelineRow(label, isCurrent, isComplete, isCancelledCurrent));
        }
    }

    private View createTimelineRow(String label, boolean isCurrent, boolean isComplete, boolean isCancelledCurrent) {
        LinearLayout row = new LinearLayout(this);
        row.setOrientation(LinearLayout.HORIZONTAL);
        row.setGravity(Gravity.CENTER_VERTICAL);
        row.setPadding(0, dp(7), 0, dp(7));

        TextView marker = new TextView(this);
        marker.setGravity(Gravity.CENTER);
        marker.setText(isCurrent ? "OK" : "");
        marker.setTextSize(13);
        marker.setTypeface(null, Typeface.BOLD);
        marker.setTextColor(getColor(isComplete || isCancelledCurrent ? R.color.white : R.color.text_secondary));
        marker.setBackgroundResource(isComplete || isCancelledCurrent ? R.drawable.bg_discount_badge : R.drawable.bg_card);
        LinearLayout.LayoutParams markerParams = new LinearLayout.LayoutParams(dp(34), dp(34));
        row.addView(marker, markerParams);

        LinearLayout textColumn = new LinearLayout(this);
        textColumn.setOrientation(LinearLayout.VERTICAL);
        LinearLayout.LayoutParams textParams = new LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.WRAP_CONTENT, 1);
        textParams.setMargins(dp(12), 0, 0, 0);
        row.addView(textColumn, textParams);

        TextView title = new TextView(this);
        title.setText(label);
        title.setTextSize(16);
        title.setTypeface(null, isCurrent ? Typeface.BOLD : Typeface.NORMAL);
        title.setTextColor(getColor(isCurrent || isComplete ? R.color.text_primary : R.color.text_secondary));
        textColumn.addView(title);

        TextView subText = new TextView(this);
        subText.setText(statusHelperText(label, isCurrent, isComplete, isCancelledCurrent));
        subText.setTextSize(12);
        subText.setTextColor(getColor(R.color.text_secondary));
        subText.setPadding(0, dp(2), 0, 0);
        textColumn.addView(subText);

        return row;
    }

    private String statusHelperText(String label, boolean isCurrent, boolean isComplete, boolean isCancelledCurrent) {
        if (isCancelledCurrent) {
            return "This order was cancelled";
        }
        if (isCurrent) {
            return "Current status";
        }
        if (isComplete) {
            return "Completed";
        }
        return "Waiting";
    }

    private int resolveStatusIndex(String status) {
        String normalized = normalizeStatus(status);
        if ("confirmed".equals(normalized) || "accepted".equals(normalized)
                || "placed".equals(normalized) || "order placed".equals(normalized)) {
            return 1;
        }
        if ("processing".equals(normalized) || "packed".equals(normalized) || "ready".equals(normalized)) {
            return 2;
        }
        if ("shipped".equals(normalized) || "dispatch".equals(normalized) || "dispatched".equals(normalized)) {
            return 3;
        }
        if ("delivered".equals(normalized) || "completed".equals(normalized)) {
            return 4;
        }
        if ("cancelled".equals(normalized) || "canceled".equals(normalized)) {
            return 5;
        }
        return 0;
    }

    private String normalizeStatus(String status) {
        if (status == null) {
            return "pending";
        }
        return status.trim().toLowerCase(Locale.US).replace("_", " ").replace("-", " ");
    }

    private String formatDisplayStatus(String status) {
        int index = resolveStatusIndex(status);
        return TIMELINE_STATUSES[index];
    }

    private String value(String value, String fallback) {
        return value == null || value.trim().isEmpty() ? fallback : value.trim();
    }

    private String formatMoney(double value) {
        return "$" + String.format(Locale.US, "%.2f", value);
    }

    private int dp(int value) {
        return (int) (value * getResources().getDisplayMetrics().density);
    }
}
