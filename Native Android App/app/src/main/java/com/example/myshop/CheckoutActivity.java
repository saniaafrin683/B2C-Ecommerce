package com.example.myshop;

import android.app.Activity;
import android.content.Intent;
import android.net.Uri;
import android.os.Bundle;
import android.view.View;
import android.widget.Button;
import android.widget.EditText;
import android.widget.RadioGroup;
import android.widget.TextView;
import android.widget.Toast;

import com.example.myshop.model.ApplyCouponRequest;
import com.example.myshop.model.ApplyCouponResponse;
import com.example.myshop.model.CartItem;
import com.example.myshop.model.OrderDetails;
import com.example.myshop.model.OrderItemRequest;
import com.example.myshop.model.OrderRequest;
import com.example.myshop.model.PaymentInitiateRequest;
import com.example.myshop.model.PaymentInitiateResponse;
import com.example.myshop.network.ApiErrorParser;
import com.example.myshop.network.RetrofitClient;
import com.example.myshop.storage.CartManager;
import com.example.myshop.storage.SessionManager;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Date;
import java.util.List;
import java.util.Locale;

import retrofit2.Call;
import retrofit2.Callback;
import retrofit2.Response;

public class CheckoutActivity extends Activity {
    private CartManager cartManager;
    private SessionManager sessionManager;
    private EditText phoneInput;
    private EditText addressInput;
    private EditText promoInput;
    private TextView subtotalText;
    private TextView discountText;
    private TextView deliveryText;
    private TextView checkoutTotalText;
    private TextView promoMessageText;
    private Button placeOrderButton;
    private RadioGroup paymentMethodGroup;
    private BigDecimal deliveryCharge = BigDecimal.ZERO;
    private BigDecimal couponDiscount = BigDecimal.ZERO;
    private String appliedCouponCode;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        ThemeManager.applyTheme(this);
        setContentView(R.layout.activity_checkout);
        cartManager = new CartManager(this);
        sessionManager = new SessionManager(this);

        if (!sessionManager.isLoggedIn()) {
            startActivity(new Intent(this, LoginActivity.class));
            finish();
            return;
        }

        phoneInput = findViewById(R.id.checkoutPhoneInput);
        addressInput = findViewById(R.id.checkoutAddressInput);
        promoInput = findViewById(R.id.promoCodeInput);
        subtotalText = findViewById(R.id.checkoutSubtotalText);
        discountText = findViewById(R.id.checkoutDiscountText);
        deliveryText = findViewById(R.id.checkoutDeliveryText);
        checkoutTotalText = findViewById(R.id.checkoutTotalText);
        promoMessageText = findViewById(R.id.promoMessageText);
        placeOrderButton = findViewById(R.id.placeOrderButton);
        paymentMethodGroup = findViewById(R.id.paymentMethodGroup);
        findViewById(R.id.backButton).setOnClickListener(view -> finish());
        findViewById(R.id.applyPromoButton).setOnClickListener(view -> applyPromoCode());
        placeOrderButton.setOnClickListener(view -> placeOrder());
        paymentMethodGroup.setOnCheckedChangeListener((group, checkedId) -> updatePlaceOrderButtonText(false));
        updateTotals();
        updatePlaceOrderButtonText(false);
    }

    private void applyPromoCode() {
        String code = promoInput.getText().toString().trim().toUpperCase(Locale.US);
        if (code.isEmpty()) {
            promoInput.setError("Enter a promo code.");
            return;
        }

        List<CartItem> cartItems = cartManager.getItems();
        if (cartItems.isEmpty()) {
            Toast.makeText(this, "Your bag is empty.", Toast.LENGTH_SHORT).show();
            return;
        }

        List<OrderItemRequest> orderItems = buildOrderItems(cartItems);
        BigDecimal subtotal = cartManager.getDiscountedSubtotal();
        RetrofitClient.getApiService()
                .applyCoupon(new ApplyCouponRequest(code, subtotal.doubleValue(), orderItems))
                .enqueue(new Callback<ApplyCouponResponse>() {
                    @Override
                    public void onResponse(Call<ApplyCouponResponse> call, Response<ApplyCouponResponse> response) {
                        if (response.isSuccessful() && response.body() != null && response.body().getCouponDiscount() != null) {
                            applyBackendCoupon(code, response.body());
                            return;
                        }
                        applyLocalCoupon(code);
                    }

                    @Override
                    public void onFailure(Call<ApplyCouponResponse> call, Throwable throwable) {
                        applyLocalCoupon(code);
                    }
                });
    }

    private void placeOrder() {
        List<CartItem> cartItems = cartManager.getItems();
        if (cartItems.isEmpty()) {
            Toast.makeText(this, "Your bag is empty.", Toast.LENGTH_SHORT).show();
            return;
        }

        String phone = phoneInput.getText().toString().trim();
        String address = addressInput.getText().toString().trim();
        boolean hasValidationError = false;
        if (phone.isEmpty()) {
            phoneInput.setError("Phone number is required.");
            hasValidationError = true;
        }
        if (address.isEmpty()) {
            addressInput.setError("Shipping address is required.");
            hasValidationError = true;
        }
        if (hasValidationError) {
            Toast.makeText(this, "Please complete the required checkout fields.", Toast.LENGTH_SHORT).show();
            return;
        }

        List<OrderItemRequest> orderItems = buildOrderItems(cartItems);

        BigDecimal regularSubtotal = cartManager.getRegularSubtotal();
        BigDecimal productDiscountTotal = cartManager.getDiscountTotal();
        BigDecimal subtotalAfterProductDiscount = cartManager.getDiscountedSubtotal();
        BigDecimal finalTotal = getFinalTotal();
        String today = new SimpleDateFormat("yyyy-MM-dd", Locale.US).format(new Date());
        String reference = "STY-" + System.currentTimeMillis();

        OrderRequest request = new OrderRequest(
                reference,
                today,
                sessionManager.getCustomerName(),
                sessionManager.getCustomerEmail(),
                phone,
                address,
                regularSubtotal.doubleValue(),
                productDiscountTotal.doubleValue(),
                subtotalAfterProductDiscount.doubleValue(),
                couponDiscount.doubleValue(),
                deliveryCharge.doubleValue(),
                appliedCouponCode,
                finalTotal.doubleValue(),
                getSelectedPaymentMethod(),
                orderItems
        );

        setSubmitting(true);
        RetrofitClient.getApiService().createOrder(authHeader(), request).enqueue(new Callback<OrderDetails>() {
            @Override
            public void onResponse(Call<OrderDetails> call, Response<OrderDetails> response) {
                setSubmitting(false);
                if (!response.isSuccessful()) {
                    Toast.makeText(CheckoutActivity.this, ApiErrorParser.getMessage(response), Toast.LENGTH_LONG).show();
                    return;
                }
                if (isOnlinePaymentSelected()) {
                    OrderDetails order = response.body();
                    if (order == null || order.getDatabaseId() == null) {
                        Toast.makeText(CheckoutActivity.this, "Order created, but payment could not start.", Toast.LENGTH_LONG).show();
                        return;
                    }
                    initiateOnlinePayment(order.getDatabaseId());
                    return;
                }
                cartManager.clear();
                Toast.makeText(CheckoutActivity.this, "Order placed successfully.", Toast.LENGTH_LONG).show();
                Intent intent = new Intent(CheckoutActivity.this, OrdersActivity.class);
                intent.addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP);
                startActivity(intent);
                finish();
            }

            @Override
            public void onFailure(Call<OrderDetails> call, Throwable throwable) {
                setSubmitting(false);
                Toast.makeText(CheckoutActivity.this, "Cannot connect to order server.", Toast.LENGTH_SHORT).show();
            }
        });
    }

    private void initiateOnlinePayment(Long orderId) {
        setSubmitting(true);
        RetrofitClient.getApiService()
                .initiatePayment(authHeader(), new PaymentInitiateRequest(orderId))
                .enqueue(new Callback<PaymentInitiateResponse>() {
                    @Override
                    public void onResponse(Call<PaymentInitiateResponse> call, Response<PaymentInitiateResponse> response) {
                        setSubmitting(false);
                        if (!response.isSuccessful() || response.body() == null || response.body().getPaymentUrl() == null) {
                            Toast.makeText(CheckoutActivity.this, ApiErrorParser.getMessage(response), Toast.LENGTH_LONG).show();
                            return;
                        }
                        cartManager.clear();
                        openPaymentUrl(response.body().getPaymentUrl());
                    }

                    @Override
                    public void onFailure(Call<PaymentInitiateResponse> call, Throwable throwable) {
                        setSubmitting(false);
                        Toast.makeText(CheckoutActivity.this, "Cannot connect to payment server.", Toast.LENGTH_SHORT).show();
                    }
                });
    }

    private void openPaymentUrl(String paymentUrl) {
        Intent browserIntent = new Intent(Intent.ACTION_VIEW, Uri.parse(paymentUrl));
        try {
            startActivity(browserIntent);
            finish();
        } catch (Exception ex) {
            Toast.makeText(this, "No browser app is available for payment.", Toast.LENGTH_LONG).show();
        }
    }

    private String authHeader() {
        return "Bearer " + sessionManager.getToken();
    }

    private String getSelectedPaymentMethod() {
        return isOnlinePaymentSelected() ? "SSLCommerz" : "Cash on Delivery";
    }

    private boolean isOnlinePaymentSelected() {
        return paymentMethodGroup != null && paymentMethodGroup.getCheckedRadioButtonId() == R.id.onlinePaymentRadio;
    }

    private List<OrderItemRequest> buildOrderItems(List<CartItem> cartItems) {
        List<OrderItemRequest> orderItems = new ArrayList<>();
        for (CartItem item : cartItems) {
            double original = item.getPrice() == null ? 0.0 : item.getPrice().doubleValue();
            double discounted = cartManager.getDiscountedPrice(item).doubleValue();
            orderItems.add(new OrderItemRequest(item, original, discounted));
        }
        return orderItems;
    }

    private void applyBackendCoupon(String code, ApplyCouponResponse response) {
        couponDiscount = money(response.getCouponDiscount());
        appliedCouponCode = response.getCouponCode() == null ? code : response.getCouponCode();
        promoMessageText.setText(response.getMessage() == null ? "Promo code applied." : response.getMessage());
        promoMessageText.setTextColor(getColor(R.color.primary));
        updateTotals();
    }

    private void applyLocalCoupon(String code) {
        BigDecimal subtotal = cartManager.getDiscountedSubtotal();
        if ("WELCOME10".equals(code)) {
            couponDiscount = subtotal.multiply(new BigDecimal("0.10")).setScale(2, RoundingMode.HALF_UP);
            appliedCouponCode = code;
            promoMessageText.setText("WELCOME10 applied: 10% off.");
            promoMessageText.setTextColor(getColor(R.color.primary));
        } else if ("STYLEORA50".equals(code)) {
            couponDiscount = subtotal.min(new BigDecimal("50.00")).setScale(2, RoundingMode.HALF_UP);
            appliedCouponCode = code;
            promoMessageText.setText("STYLEORA50 applied: 50 taka off.");
            promoMessageText.setTextColor(getColor(R.color.primary));
        } else {
            couponDiscount = BigDecimal.ZERO;
            appliedCouponCode = null;
            promoMessageText.setText("Invalid promo code.");
            promoMessageText.setTextColor(getColor(R.color.danger));
        }
        updateTotals();
    }

    private void updateTotals() {
        BigDecimal subtotal = cartManager.getDiscountedSubtotal();
        if (couponDiscount.compareTo(subtotal) > 0) {
            couponDiscount = subtotal;
        }
        subtotalText.setText("Subtotal: " + formatMoney(subtotal));
        discountText.setText("Discount: -" + formatMoney(couponDiscount));
        deliveryText.setText("Delivery charge: " + formatMoney(deliveryCharge));
        checkoutTotalText.setText("Final total: " + formatMoney(getFinalTotal()));
    }

    private BigDecimal getFinalTotal() {
        BigDecimal subtotal = cartManager.getDiscountedSubtotal();
        BigDecimal total = subtotal.subtract(couponDiscount).add(deliveryCharge);
        return total.max(BigDecimal.ZERO).setScale(2, RoundingMode.HALF_UP);
    }

    private BigDecimal money(Double value) {
        return BigDecimal.valueOf(value == null ? 0.0 : value).setScale(2, RoundingMode.HALF_UP);
    }

    private String formatMoney(BigDecimal value) {
        return "$" + value.setScale(2, RoundingMode.HALF_UP).stripTrailingZeros().toPlainString();
    }

    private void setSubmitting(boolean submitting) {
        placeOrderButton.setEnabled(!submitting);
        updatePlaceOrderButtonText(submitting);
        findViewById(R.id.checkoutProgressBar).setVisibility(submitting ? View.VISIBLE : View.GONE);
    }

    private void updatePlaceOrderButtonText(boolean submitting) {
        if (submitting) {
            placeOrderButton.setText(isOnlinePaymentSelected() ? "Starting Payment..." : "Placing Order...");
            return;
        }
        placeOrderButton.setText(isOnlinePaymentSelected() ? "Pay Online" : "Place Order");
    }
}
