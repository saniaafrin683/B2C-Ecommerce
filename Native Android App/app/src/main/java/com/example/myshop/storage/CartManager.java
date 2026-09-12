package com.example.myshop.storage;

import android.content.Context;
import android.content.SharedPreferences;

import com.example.myshop.model.CartItem;
import com.example.myshop.model.Product;
import com.google.gson.reflect.TypeToken;
import com.example.myshop.network.RetrofitClient;

import java.lang.reflect.Type;
import java.math.BigDecimal;
import java.math.RoundingMode;
import java.util.ArrayList;
import java.util.List;

public class CartManager {
    private static final String PREFS_NAME = "styleora_cart";
    private static final String KEY_ITEMS = "items";

    private final SharedPreferences preferences;
    private final Type itemListType = new TypeToken<List<CartItem>>() { }.getType();

    public CartManager(Context context) {
        preferences = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE);
    }

    public List<CartItem> getItems() {
        String json = preferences.getString(KEY_ITEMS, "");
        if (json == null || json.trim().isEmpty()) {
            return new ArrayList<>();
        }
        try {
            List<CartItem> items = RetrofitClient.getGson().fromJson(json, itemListType);
            return items == null ? new ArrayList<>() : items;
        } catch (Exception ignored) {
            return new ArrayList<>();
        }
    }

    public void addProduct(Product product, int quantity, String size) {
        if (product == null || product.getId() == null) {
            return;
        }
        List<CartItem> items = getItems();
        String normalizedSize = size == null ? "" : size.trim();
        for (CartItem item : items) {
            if (product.getId().equals(item.getProductId())
                    && normalizedSize.equals(item.getSize() == null ? "" : item.getSize())) {
                item.setQuantity(item.getQuantity() + Math.max(1, quantity));
                saveItems(items);
                return;
            }
        }
        items.add(new CartItem(product, Math.max(1, quantity), normalizedSize));
        saveItems(items);
    }

    public void updateQuantity(Long productId, String size, int quantity) {
        List<CartItem> items = getItems();
        String normalizedSize = size == null ? "" : size.trim();
        for (int i = items.size() - 1; i >= 0; i--) {
            CartItem item = items.get(i);
            if (item.getProductId().equals(productId)
                    && normalizedSize.equals(item.getSize() == null ? "" : item.getSize())) {
                if (quantity <= 0) {
                    items.remove(i);
                } else {
                    item.setQuantity(quantity);
                }
                break;
            }
        }
        saveItems(items);
    }

    public void clear() {
        saveItems(new ArrayList<>());
    }

    public int getCount() {
        int count = 0;
        for (CartItem item : getItems()) {
            count += item.getQuantity();
        }
        return count;
    }

    public BigDecimal getRegularSubtotal() {
        BigDecimal total = BigDecimal.ZERO;
        for (CartItem item : getItems()) {
            total = total.add(nullToZero(item.getPrice()).multiply(BigDecimal.valueOf(item.getQuantity())));
        }
        return total.setScale(2, RoundingMode.HALF_UP);
    }

    public BigDecimal getDiscountedSubtotal() {
        BigDecimal total = BigDecimal.ZERO;
        for (CartItem item : getItems()) {
            total = total.add(getDiscountedPrice(item).multiply(BigDecimal.valueOf(item.getQuantity())));
        }
        return total.setScale(2, RoundingMode.HALF_UP);
    }

    public BigDecimal getDiscountTotal() {
        return getRegularSubtotal().subtract(getDiscountedSubtotal()).setScale(2, RoundingMode.HALF_UP);
    }

    public BigDecimal getDiscountedPrice(CartItem item) {
        BigDecimal price = nullToZero(item.getPrice());
        BigDecimal discount = nullToZero(item.getDiscount()).max(BigDecimal.ZERO).min(BigDecimal.valueOf(100));
        return price.multiply(BigDecimal.valueOf(100).subtract(discount))
                .divide(BigDecimal.valueOf(100), 2, RoundingMode.HALF_UP);
    }

    private BigDecimal nullToZero(BigDecimal value) {
        return value == null ? BigDecimal.ZERO : value;
    }

    private void saveItems(List<CartItem> items) {
        preferences.edit().putString(KEY_ITEMS, RetrofitClient.getGson().toJson(items)).apply();
    }
}
