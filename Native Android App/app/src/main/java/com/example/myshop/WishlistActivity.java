package com.example.myshop;

import android.app.Activity;
import android.content.Intent;
import android.os.Bundle;
import android.view.View;
import android.widget.TextView;

import androidx.recyclerview.widget.GridLayoutManager;
import androidx.recyclerview.widget.RecyclerView;

import com.example.myshop.adapter.ProductAdapter;
import com.example.myshop.storage.WishlistManager;

public class WishlistActivity extends Activity {
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        ThemeManager.applyTheme(this);
        setContentView(R.layout.activity_wishlist);

        findViewById(R.id.backButton).setOnClickListener(view -> finish());
        TextView emptyText = findViewById(R.id.wishlistEmptyText);
        RecyclerView recyclerView = findViewById(R.id.wishlistRecyclerView);
        WishlistManager wishlistManager = new WishlistManager(this);

        ProductAdapter adapter = new ProductAdapter(wishlistManager.getItems(), product -> {
            Intent intent = new Intent(this, ProductDetailsActivity.class);
            intent.putExtra(ProductDetailsActivity.EXTRA_PRODUCT_ID, product.getId());
            startActivity(intent);
        });
        recyclerView.setLayoutManager(new GridLayoutManager(this, 2));
        recyclerView.setAdapter(adapter);
        emptyText.setVisibility(wishlistManager.getItems().isEmpty() ? View.VISIBLE : View.GONE);
    }
}
