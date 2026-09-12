package com.example.myshop;

import android.app.Activity;
import android.os.Bundle;
import android.view.View;
import android.widget.ArrayAdapter;
import android.widget.Button;
import android.widget.EditText;
import android.widget.ProgressBar;
import android.widget.RatingBar;
import android.widget.Spinner;
import android.widget.TextView;
import android.widget.Toast;

import com.example.myshop.model.OrderDetails;
import com.example.myshop.model.OrderItemRequest;
import com.example.myshop.model.Review;
import com.example.myshop.model.ReviewSubmitRequest;
import com.example.myshop.network.ApiErrorParser;
import com.example.myshop.network.RetrofitClient;
import com.example.myshop.storage.SessionManager;

import java.util.ArrayList;
import java.util.List;
import java.util.Locale;

import retrofit2.Call;
import retrofit2.Callback;
import retrofit2.Response;

public class WriteReviewActivity extends Activity {
    public static final String EXTRA_ORDER_DB_ID = "order_db_id";

    private SessionManager sessionManager;
    private ProgressBar progressBar;
    private TextView orderText;
    private Spinner productSpinner;
    private RatingBar ratingBar;
    private EditText commentInput;
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

        setContentView(R.layout.activity_write_review);
        findViewById(R.id.backButton).setOnClickListener(view -> finish());
        progressBar = findViewById(R.id.reviewProgressBar);
        orderText = findViewById(R.id.reviewOrderText);
        productSpinner = findViewById(R.id.reviewProductSpinner);
        ratingBar = findViewById(R.id.reviewRatingBar);
        commentInput = findViewById(R.id.reviewCommentInput);
        submitButton = findViewById(R.id.reviewSubmitButton);
        submitButton.setOnClickListener(view -> submitReview());

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
                            Toast.makeText(WriteReviewActivity.this, ApiErrorParser.getMessage(response), Toast.LENGTH_LONG).show();
                            finish();
                            return;
                        }
                        bindOrder(response.body());
                    }

                    @Override
                    public void onFailure(Call<OrderDetails> call, Throwable throwable) {
                        setLoading(false);
                        Toast.makeText(WriteReviewActivity.this, "Unable to load order.", Toast.LENGTH_SHORT).show();
                        finish();
                    }
                });
    }

    private void bindOrder(OrderDetails order) {
        if (!isDelivered(order)) {
            Toast.makeText(this, "Reviews can only be submitted after delivery.", Toast.LENGTH_LONG).show();
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
            Toast.makeText(this, "No reviewable products found for this order.", Toast.LENGTH_LONG).show();
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

    private void submitReview() {
        ProductOption product = (ProductOption) productSpinner.getSelectedItem();
        int rating = Math.round(ratingBar.getRating());
        String comment = commentInput.getText().toString().trim();

        if (product == null) {
            Toast.makeText(this, "Select a product.", Toast.LENGTH_SHORT).show();
            return;
        }
        if (rating < 1 || rating > 5) {
            Toast.makeText(this, "Select a rating from 1 to 5 stars.", Toast.LENGTH_SHORT).show();
            return;
        }
        if (comment.isEmpty()) {
            commentInput.setError("Write a review comment.");
            commentInput.requestFocus();
            return;
        }

        setLoading(true);
        RetrofitClient.getApiService()
                .submitReview(authHeader(), new ReviewSubmitRequest(orderDbId, product.productId, rating, comment))
                .enqueue(new Callback<Review>() {
                    @Override
                    public void onResponse(Call<Review> call, Response<Review> response) {
                        setLoading(false);
                        if (response.isSuccessful()) {
                            Toast.makeText(WriteReviewActivity.this, "Review submitted for approval.", Toast.LENGTH_LONG).show();
                            finish();
                            return;
                        }
                        Toast.makeText(WriteReviewActivity.this, ApiErrorParser.getMessage(response), Toast.LENGTH_LONG).show();
                    }

                    @Override
                    public void onFailure(Call<Review> call, Throwable throwable) {
                        setLoading(false);
                        Toast.makeText(WriteReviewActivity.this, "Unable to submit review.", Toast.LENGTH_SHORT).show();
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
