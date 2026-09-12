package com.example.myshop;

import android.app.Activity;
import android.os.Bundle;
import android.view.View;
import android.widget.ArrayAdapter;
import android.widget.Button;
import android.widget.EditText;
import android.widget.ProgressBar;
import android.widget.Spinner;
import android.widget.TextView;
import android.widget.Toast;

import com.example.myshop.model.OrderDetails;
import com.example.myshop.model.OrderItemRequest;
import com.example.myshop.model.ReturnRequest;
import com.example.myshop.model.ReturnRequestCreateRequest;
import com.example.myshop.network.ApiErrorParser;
import com.example.myshop.network.RetrofitClient;
import com.example.myshop.storage.SessionManager;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import java.util.Locale;

import retrofit2.Call;
import retrofit2.Callback;
import retrofit2.Response;

public class ReturnRequestActivity extends Activity {
    public static final String EXTRA_ORDER_DB_ID = "order_db_id";

    private static final List<String> REASONS = Arrays.asList(
            "Wrong size",
            "Damaged product",
            "Wrong item",
            "Quality issue",
            "Other"
    );

    private SessionManager sessionManager;
    private ProgressBar progressBar;
    private TextView orderText;
    private Spinner productSpinner;
    private Spinner reasonSpinner;
    private EditText detailsInput;
    private Button submitButton;
    private long orderDbId;
    private final List<ProductOption> productOptions = new ArrayList<>();

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        ThemeManager.applyTheme(this);
        sessionManager = new SessionManager(this);
        if (!sessionManager.isLoggedIn()) {
            finish();
            return;
        }

        setContentView(R.layout.activity_return_request);
        findViewById(R.id.backButton).setOnClickListener(view -> finish());
        progressBar = findViewById(R.id.returnProgressBar);
        orderText = findViewById(R.id.returnOrderText);
        productSpinner = findViewById(R.id.returnProductSpinner);
        reasonSpinner = findViewById(R.id.returnReasonSpinner);
        detailsInput = findViewById(R.id.returnDetailsInput);
        submitButton = findViewById(R.id.returnSubmitButton);
        submitButton.setOnClickListener(view -> submitReturnRequest());

        ArrayAdapter<String> reasonAdapter = new ArrayAdapter<>(
                this,
                R.layout.item_spinner_text,
                REASONS
        );
        reasonAdapter.setDropDownViewResource(R.layout.item_spinner_dropdown_text);
        reasonSpinner.setAdapter(reasonAdapter);

        orderDbId = getIntent().getLongExtra(EXTRA_ORDER_DB_ID, -1L);
        if (orderDbId <= 0) {
            Toast.makeText(this, "Order is not available.", Toast.LENGTH_SHORT).show();
            finish();
            return;
        }

        loadOrder();
    }

    private void loadOrder() {
        setLoading(true);
        RetrofitClient.getApiService()
                .getMyOrderById(authHeader(), orderDbId)
                .enqueue(new Callback<OrderDetails>() {
                    @Override
                    public void onResponse(Call<OrderDetails> call, Response<OrderDetails> response) {
                        setLoading(false);
                        if (!response.isSuccessful() || response.body() == null) {
                            Toast.makeText(ReturnRequestActivity.this, ApiErrorParser.getMessage(response), Toast.LENGTH_LONG).show();
                            finish();
                            return;
                        }
                        bindOrder(response.body());
                    }

                    @Override
                    public void onFailure(Call<OrderDetails> call, Throwable throwable) {
                        setLoading(false);
                        Toast.makeText(ReturnRequestActivity.this, "Unable to load order.", Toast.LENGTH_SHORT).show();
                        finish();
                    }
                });
    }

    private void bindOrder(OrderDetails order) {
        if (!isDelivered(order)) {
            Toast.makeText(this, "Returns can only be requested after delivery.", Toast.LENGTH_LONG).show();
            finish();
            return;
        }

        orderText.setText(value(order.getOrderId(), "Order"));
        productOptions.clear();
        if (order.getOrderItems() != null) {
            for (OrderItemRequest item : order.getOrderItems()) {
                if (item.getProductId() != null) {
                    productOptions.add(new ProductOption(item.getProductId(), value(item.getProductName(), "Product")));
                }
            }
        }

        if (productOptions.isEmpty()) {
            Toast.makeText(this, "No returnable products found for this order.", Toast.LENGTH_LONG).show();
            submitButton.setEnabled(false);
            return;
        }

        ArrayAdapter<ProductOption> adapter = new ArrayAdapter<>(
                this,
                R.layout.item_spinner_text,
                productOptions
        );
        adapter.setDropDownViewResource(R.layout.item_spinner_dropdown_text);
        productSpinner.setAdapter(adapter);
        submitButton.setEnabled(true);
    }

    private void submitReturnRequest() {
        ProductOption product = (ProductOption) productSpinner.getSelectedItem();
        String reason = reasonSpinner.getSelectedItem() == null ? "" : reasonSpinner.getSelectedItem().toString();
        String details = detailsInput.getText().toString().trim();

        if (product == null) {
            Toast.makeText(this, "Select a product.", Toast.LENGTH_SHORT).show();
            return;
        }
        if (reason.trim().isEmpty()) {
            Toast.makeText(this, "Select a return reason.", Toast.LENGTH_SHORT).show();
            return;
        }

        setLoading(true);
        RetrofitClient.getApiService()
                .requestReturn(authHeader(), new ReturnRequestCreateRequest(orderDbId, product.productId, reason, details))
                .enqueue(new Callback<ReturnRequest>() {
                    @Override
                    public void onResponse(Call<ReturnRequest> call, Response<ReturnRequest> response) {
                        setLoading(false);
                        if (response.isSuccessful()) {
                            Toast.makeText(ReturnRequestActivity.this, "Return request submitted.", Toast.LENGTH_LONG).show();
                            finish();
                            return;
                        }
                        Toast.makeText(ReturnRequestActivity.this, ApiErrorParser.getMessage(response), Toast.LENGTH_LONG).show();
                    }

                    @Override
                    public void onFailure(Call<ReturnRequest> call, Throwable throwable) {
                        setLoading(false);
                        Toast.makeText(ReturnRequestActivity.this, "Unable to submit return request.", Toast.LENGTH_SHORT).show();
                    }
                });
    }

    private void setLoading(boolean loading) {
        progressBar.setVisibility(loading ? View.VISIBLE : View.GONE);
        submitButton.setEnabled(!loading && !productOptions.isEmpty());
    }

    private String authHeader() {
        return "Bearer " + sessionManager.getToken();
    }

    private boolean isDelivered(OrderDetails order) {
        return isDeliveredStatus(order.getOrderStatus()) || isDeliveredStatus(order.getShipmentStatus());
    }

    private boolean isDeliveredStatus(String status) {
        return status != null && "delivered".equals(status.trim().toLowerCase(Locale.US).replace("_", " ").replace("-", " "));
    }

    private String value(String value, String fallback) {
        return value == null || value.trim().isEmpty() ? fallback : value.trim();
    }

    private static class ProductOption {
        private final Long productId;
        private final String name;

        ProductOption(Long productId, String name) {
            this.productId = productId;
            this.name = name;
        }

        @Override
        public String toString() {
            return name;
        }
    }
}
