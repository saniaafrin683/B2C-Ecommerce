package com.example.myshop;

import android.app.Activity;
import android.content.Intent;
import android.os.Bundle;
import android.view.Gravity;
import android.view.View;
import android.widget.Button;
import android.widget.ImageButton;
import android.widget.ImageView;
import android.widget.LinearLayout;
import android.widget.TextView;

import com.bumptech.glide.Glide;
import com.example.myshop.model.CartItem;
import com.example.myshop.network.RetrofitClient;
import com.example.myshop.storage.CartManager;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.util.List;

public class CartActivity extends Activity {
    private CartManager cartManager;
    private LinearLayout cartContainer;
    private TextView emptyText;
    private TextView totalText;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        ThemeManager.applyTheme(this);
        setContentView(R.layout.activity_cart);
        cartManager = new CartManager(this);
        cartContainer = findViewById(R.id.cartContainer);
        emptyText = findViewById(R.id.cartEmptyText);
        totalText = findViewById(R.id.cartTotalText);

        findViewById(R.id.backButton).setOnClickListener(view -> finish());
        findViewById(R.id.checkoutButton).setOnClickListener(view -> startActivity(new Intent(this, CheckoutActivity.class)));
    }

    @Override
    protected void onResume() {
        super.onResume();
        bindCart();
    }

    private void bindCart() {
        List<CartItem> items = cartManager.getItems();
        cartContainer.removeAllViews();
        emptyText.setVisibility(items.isEmpty() ? View.VISIBLE : View.GONE);
        findViewById(R.id.checkoutButton).setEnabled(!items.isEmpty());
        for (CartItem item : items) {
            cartContainer.addView(createCartRow(item));
        }
        totalText.setText("Total: " + formatMoney(cartManager.getDiscountedSubtotal()));
    }

    private View createCartRow(CartItem item) {
        LinearLayout row = new LinearLayout(this);
        row.setOrientation(LinearLayout.HORIZONTAL);
        row.setPadding(dp(10), dp(10), dp(10), dp(10));
        row.setGravity(Gravity.CENTER_VERTICAL);
        row.setBackgroundResource(R.drawable.bg_card);
        LinearLayout.LayoutParams rowParams = new LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
        );
        rowParams.setMargins(0, 0, 0, dp(12));
        row.setLayoutParams(rowParams);

        ImageView image = new ImageView(this);
        image.setScaleType(ImageView.ScaleType.CENTER_CROP);
        Glide.with(this).load(buildImageUrl(item.getImageUrl()))
                .placeholder(R.drawable.ic_product_placeholder)
                .error(R.drawable.ic_product_placeholder)
                .into(image);
        row.addView(image, new LinearLayout.LayoutParams(dp(86), dp(100)));

        LinearLayout info = new LinearLayout(this);
        info.setOrientation(LinearLayout.VERTICAL);
        info.setPadding(dp(12), 0, 0, 0);
        row.addView(info, new LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.WRAP_CONTENT, 1));

        TextView name = new TextView(this);
        name.setText(item.getName());
        name.setTextColor(getColor(R.color.text_primary));
        name.setTextSize(15);
        name.setTypeface(null, android.graphics.Typeface.BOLD);
        info.addView(name);

        TextView price = new TextView(this);
        price.setText(formatMoney(cartManager.getDiscountedPrice(item)));
        price.setTextColor(getColor(R.color.primary));
        price.setTextSize(14);
        info.addView(price);

        LinearLayout qty = new LinearLayout(this);
        qty.setGravity(Gravity.CENTER_VERTICAL);
        qty.setPadding(0, dp(8), 0, 0);
        info.addView(qty);

        ImageButton minus = new ImageButton(this);
        minus.setImageResource(android.R.drawable.ic_media_previous);
        minus.setBackgroundResource(R.drawable.bg_card);
        qty.addView(minus, new LinearLayout.LayoutParams(dp(34), dp(34)));

        TextView count = new TextView(this);
        count.setText(String.valueOf(item.getQuantity()));
        count.setGravity(Gravity.CENTER);
        count.setTextColor(getColor(R.color.text_primary));
        qty.addView(count, new LinearLayout.LayoutParams(dp(44), dp(34)));

        ImageButton plus = new ImageButton(this);
        plus.setImageResource(android.R.drawable.ic_input_add);
        plus.setBackgroundResource(R.drawable.bg_card);
        qty.addView(plus, new LinearLayout.LayoutParams(dp(34), dp(34)));

        minus.setOnClickListener(view -> {
            cartManager.updateQuantity(item.getProductId(), item.getSize(), item.getQuantity() - 1);
            bindCart();
        });
        plus.setOnClickListener(view -> {
            cartManager.updateQuantity(item.getProductId(), item.getSize(), item.getQuantity() + 1);
            bindCart();
        });
        return row;
    }

    private String formatMoney(BigDecimal value) {
        return "$" + value.setScale(2, RoundingMode.HALF_UP).stripTrailingZeros().toPlainString();
    }

    private String buildImageUrl(String imageUrl) {
        if (imageUrl == null || imageUrl.trim().isEmpty()) {
            return null;
        }
        String value = imageUrl.trim();
        if (value.startsWith("http://") || value.startsWith("https://") || value.startsWith("data:")) {
            return value;
        }
        return RetrofitClient.getBaseUrl() + value.replaceFirst("^/+", "");
    }

    private int dp(int value) {
        return (int) (value * getResources().getDisplayMetrics().density);
    }
}
