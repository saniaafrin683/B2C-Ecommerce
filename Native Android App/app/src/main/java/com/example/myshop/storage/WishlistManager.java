package com.example.myshop.storage;

import android.content.Context;
import android.content.SharedPreferences;

import com.example.myshop.model.Product;
import com.example.myshop.network.RetrofitClient;
import com.google.gson.reflect.TypeToken;

import java.lang.reflect.Type;
import java.util.ArrayList;
import java.util.List;

public class WishlistManager {
    private static final String PREFS_NAME = "styleora_wishlist";
    private static final String KEY_ITEMS = "items";

    private final SharedPreferences preferences;
    private final Type productListType = new TypeToken<List<Product>>() { }.getType();

    public WishlistManager(Context context) {
        preferences = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE);
    }

    public List<Product> getItems() {
        String json = preferences.getString(KEY_ITEMS, "");
        if (json == null || json.trim().isEmpty()) {
            return new ArrayList<>();
        }
        try {
            List<Product> items = RetrofitClient.getGson().fromJson(json, productListType);
            return items == null ? new ArrayList<>() : items;
        } catch (Exception ignored) {
            return new ArrayList<>();
        }
    }

    public boolean toggle(Product product) {
        if (product == null || product.getId() == null) {
            return false;
        }
        List<Product> items = getItems();
        for (int i = 0; i < items.size(); i++) {
            if (product.getId().equals(items.get(i).getId())) {
                items.remove(i);
                saveItems(items);
                return false;
            }
        }
        items.add(product);
        saveItems(items);
        return true;
    }

    public boolean contains(Long productId) {
        if (productId == null) {
            return false;
        }
        for (Product product : getItems()) {
            if (productId.equals(product.getId())) {
                return true;
            }
        }
        return false;
    }

    public int getCount() {
        return getItems().size();
    }

    private void saveItems(List<Product> items) {
        preferences.edit().putString(KEY_ITEMS, RetrofitClient.getGson().toJson(items)).apply();
    }
}
