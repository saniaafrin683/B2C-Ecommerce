package com.example.myshop.adapter;

import android.graphics.Paint;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ImageView;
import android.widget.TextView;

import androidx.annotation.NonNull;
import androidx.recyclerview.widget.RecyclerView;

import com.bumptech.glide.Glide;
import com.example.myshop.R;
import com.example.myshop.model.Product;
import com.example.myshop.network.RetrofitClient;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.util.List;

public class HomeProductAdapter extends RecyclerView.Adapter<HomeProductAdapter.HomeProductViewHolder> {
    private static final int MODE_GRID = 1;
    private static final int MODE_HORIZONTAL = 2;

    private List<Product> products;
    private final int mode;
    private final OnProductClickListener clickListener;

    public interface OnProductClickListener {
        void onProductClick(Product product);
    }

    public static HomeProductAdapter grid(List<Product> products, OnProductClickListener clickListener) {
        return new HomeProductAdapter(products, MODE_GRID, clickListener);
    }

    public static HomeProductAdapter horizontal(List<Product> products, OnProductClickListener clickListener) {
        return new HomeProductAdapter(products, MODE_HORIZONTAL, clickListener);
    }

    private HomeProductAdapter(List<Product> products, int mode, OnProductClickListener clickListener) {
        this.products = products;
        this.mode = mode;
        this.clickListener = clickListener;
    }

    @NonNull
    @Override
    public HomeProductViewHolder onCreateViewHolder(@NonNull ViewGroup parent, int viewType) {
        View view = LayoutInflater.from(parent.getContext()).inflate(R.layout.item_home_product, parent, false);
        RecyclerView.LayoutParams params = new RecyclerView.LayoutParams(
                mode == MODE_HORIZONTAL ? dp(parent, 186) : ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.WRAP_CONTENT
        );
        params.setMargins(dp(parent, 6), dp(parent, 6), dp(parent, 6), dp(parent, 12));
        view.setLayoutParams(params);
        return new HomeProductViewHolder(view);
    }

    @Override
    public void onBindViewHolder(@NonNull HomeProductViewHolder holder, int position) {
        Product product = products.get(position);
        Glide.with(holder.itemView.getContext())
                .load(buildImageUrl(product.getImageUrl()))
                .placeholder(R.drawable.ic_product_placeholder)
                .error(R.drawable.ic_product_placeholder)
                .centerCrop()
                .into(holder.imageView);

        holder.nameText.setText(value(product.getName(), "StyleOra item"));
        holder.metaText.setText(value(product.getCategory(), "Fashion"));
        holder.priceText.setText(formatPrice(currentPrice(product)));
        if (hasDiscount(product)) {
            holder.oldPriceText.setText(formatPrice(product.getPrice()));
            holder.oldPriceText.setPaintFlags(holder.oldPriceText.getPaintFlags() | Paint.STRIKE_THRU_TEXT_FLAG);
            holder.oldPriceText.setVisibility(View.VISIBLE);
        } else {
            holder.oldPriceText.setVisibility(View.GONE);
        }
        holder.itemView.setOnClickListener(view -> {
            if (clickListener != null) {
                clickListener.onProductClick(product);
            }
        });
    }

    @Override
    public int getItemCount() {
        return products == null ? 0 : products.size();
    }

    public void setProducts(List<Product> products) {
        this.products = products;
        notifyDataSetChanged();
    }

    private boolean hasDiscount(Product product) {
        return product.getDiscount() != null && product.getDiscount().signum() > 0;
    }

    private BigDecimal currentPrice(Product product) {
        BigDecimal price = product.getPrice() == null ? BigDecimal.ZERO : product.getPrice();
        if (!hasDiscount(product)) {
            return price;
        }
        BigDecimal discount = product.getDiscount().max(BigDecimal.ZERO).min(BigDecimal.valueOf(100));
        return price.multiply(BigDecimal.valueOf(100).subtract(discount)).divide(BigDecimal.valueOf(100), 2, RoundingMode.HALF_UP);
    }

    private String formatPrice(BigDecimal price) {
        if (price == null) {
            return "$0";
        }
        return "$" + price.setScale(2, RoundingMode.HALF_UP).stripTrailingZeros().toPlainString();
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

    private String value(String value, String fallback) {
        return value == null || value.trim().isEmpty() ? fallback : value.trim();
    }

    private int dp(View view, int value) {
        return (int) (value * view.getResources().getDisplayMetrics().density);
    }

    static class HomeProductViewHolder extends RecyclerView.ViewHolder {
        private final ImageView imageView;
        private final TextView nameText;
        private final TextView metaText;
        private final TextView priceText;
        private final TextView oldPriceText;

        HomeProductViewHolder(@NonNull View itemView) {
            super(itemView);
            imageView = itemView.findViewById(R.id.homeProductImageView);
            nameText = itemView.findViewById(R.id.homeProductNameText);
            metaText = itemView.findViewById(R.id.homeProductMetaText);
            priceText = itemView.findViewById(R.id.homeProductPriceText);
            oldPriceText = itemView.findViewById(R.id.homeProductOldPriceText);
        }
    }
}
