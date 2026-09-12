package com.example.myshop.adapter;

import android.graphics.Paint;
import android.content.Context;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.Button;
import android.widget.ImageView;
import android.widget.TextView;
import android.widget.Toast;

import androidx.annotation.NonNull;
import androidx.recyclerview.widget.RecyclerView;

import com.example.myshop.R;
import com.example.myshop.model.Product;
import com.example.myshop.network.RetrofitClient;
import com.bumptech.glide.Glide;
import com.example.myshop.storage.CartManager;
import com.example.myshop.storage.WishlistManager;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.util.ArrayList;
import java.util.List;

public class ProductAdapter extends RecyclerView.Adapter<ProductAdapter.ProductViewHolder> {
    private List<Product> products;
    private final OnProductClickListener clickListener;

    public interface OnProductClickListener {
        void onProductClick(Product product);
    }

    public ProductAdapter(List<Product> products) {
        this(products, null);
    }

    public ProductAdapter(List<Product> products, OnProductClickListener clickListener) {
        this.products = products;
        this.clickListener = clickListener;
    }

    @NonNull
    @Override
    public ProductViewHolder onCreateViewHolder(@NonNull ViewGroup parent, int viewType) {
        View view = LayoutInflater.from(parent.getContext())
                .inflate(R.layout.item_product, parent, false);
        return new ProductViewHolder(view);
    }

    @Override
    public void onBindViewHolder(@NonNull ProductViewHolder holder, int position) {
        Product product = products.get(position);
        Context context = holder.itemView.getContext();
        BigDecimal price = product.getPrice();
        BigDecimal discount = product.getDiscount();
        boolean hasDiscount = discount != null && discount.compareTo(BigDecimal.ZERO) > 0;
        WishlistManager wishlistManager = new WishlistManager(context);

        Glide.with(context)
                .load(buildImageUrl(product.getImageUrl()))
                .placeholder(R.drawable.ic_product_placeholder)
                .error(R.drawable.ic_product_placeholder)
                .centerCrop()
                .into(holder.imageView);

        if (hasDiscount) {
            holder.discountText.setText(formatDiscount(discount));
            holder.discountText.setVisibility(View.VISIBLE);
        } else {
            holder.discountText.setVisibility(View.GONE);
        }

        holder.nameText.setText(valueOrDefault(product.getName(), "Unnamed product"));
        holder.metaText.setText(buildMeta(product));
        holder.deliveryText.setText("FREE DELIVERY");

        if (hasDiscount && price != null) {
            holder.oldPriceText.setText(formatPrice(price));
            holder.oldPriceText.setPaintFlags(holder.oldPriceText.getPaintFlags() | Paint.STRIKE_THRU_TEXT_FLAG);
            holder.oldPriceText.setVisibility(View.VISIBLE);
            holder.priceText.setText(formatPrice(applyDiscount(price, discount)));
        } else {
            holder.oldPriceText.setVisibility(View.GONE);
            holder.priceText.setText(formatPrice(price));
        }

        holder.wishlistButton.setText(wishlistManager.contains(product.getId()) ? "♥" : "♡");
        holder.wishlistButton.setOnClickListener(view -> {
            boolean added = new WishlistManager(view.getContext()).toggle(product);
            holder.wishlistButton.setText(added ? "♥" : "♡");
            Toast.makeText(view.getContext(), added ? "Added to wishlist" : "Removed from wishlist", Toast.LENGTH_SHORT).show();
        });

        holder.addToBagButton.setOnClickListener(view -> {
            new CartManager(view.getContext()).addProduct(product, 1, product.getSize());
            Toast.makeText(view.getContext(), "Added to bag", Toast.LENGTH_SHORT).show();
        });

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

    private String buildMeta(Product product) {
        List<String> parts = new ArrayList<>();
        addIfPresent(parts, product.getCategory());
        addIfPresent(parts, product.getBrand());
        addIfPresent(parts, product.getWeight());
        if (parts.isEmpty()) {
            addIfPresent(parts, product.getSubCategory());
        }
        return parts.isEmpty() ? "Fashion essential" : joinParts(parts);
    }

    private void addIfPresent(List<String> parts, String value) {
        if (value != null && !value.trim().isEmpty()) {
            parts.add(value.trim());
        }
    }

    private String joinParts(List<String> parts) {
        StringBuilder builder = new StringBuilder();
        for (int i = 0; i < parts.size(); i++) {
            if (i > 0) {
                builder.append(" / ");
            }
            builder.append(parts.get(i));
        }
        return builder.toString();
    }

    private String formatPrice(BigDecimal price) {
        if (price == null) {
            return "$--";
        }
        return "$" + price.setScale(2, RoundingMode.HALF_UP).stripTrailingZeros().toPlainString();
    }

    private String formatDiscount(BigDecimal discount) {
        return discount.setScale(0, RoundingMode.HALF_UP).toPlainString() + "% OFF";
    }

    private BigDecimal applyDiscount(BigDecimal price, BigDecimal discount) {
        BigDecimal safeDiscount = discount.min(new BigDecimal("100"));
        BigDecimal multiplier = new BigDecimal("100").subtract(safeDiscount);
        return price.multiply(multiplier).divide(new BigDecimal("100"), 2, RoundingMode.HALF_UP);
    }

    private String buildImageUrl(String imageUrl) {
        if (imageUrl == null || imageUrl.trim().isEmpty()) {
            return null;
        }
        String trimmedUrl = imageUrl.trim();
        if (trimmedUrl.startsWith("http://") || trimmedUrl.startsWith("https://")) {
            return trimmedUrl;
        }
        if (trimmedUrl.startsWith("/")) {
            trimmedUrl = trimmedUrl.substring(1);
        }
        return RetrofitClient.getBaseUrl() + trimmedUrl;
    }

    private String valueOrDefault(String value, String fallback) {
        return value == null || value.trim().isEmpty() ? fallback : value;
    }

    static class ProductViewHolder extends RecyclerView.ViewHolder {
        private final ImageView imageView;
        private final TextView discountText;
        private final TextView wishlistButton;
        private final TextView nameText;
        private final TextView metaText;
        private final TextView deliveryText;
        private final TextView oldPriceText;
        private final TextView priceText;
        private final Button addToBagButton;

        ProductViewHolder(@NonNull View itemView) {
            super(itemView);
            imageView = itemView.findViewById(R.id.productImageView);
            discountText = itemView.findViewById(R.id.productDiscountText);
            wishlistButton = itemView.findViewById(R.id.productWishlistButton);
            nameText = itemView.findViewById(R.id.productNameText);
            metaText = itemView.findViewById(R.id.productMetaText);
            deliveryText = itemView.findViewById(R.id.productDeliveryText);
            oldPriceText = itemView.findViewById(R.id.productOldPriceText);
            priceText = itemView.findViewById(R.id.productPriceText);
            addToBagButton = itemView.findViewById(R.id.addToBagButton);
        }
    }
}
