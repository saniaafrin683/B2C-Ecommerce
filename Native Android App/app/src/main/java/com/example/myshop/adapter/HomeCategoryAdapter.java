package com.example.myshop.adapter;

import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ImageView;
import android.widget.TextView;

import androidx.annotation.NonNull;
import androidx.recyclerview.widget.RecyclerView;

import com.bumptech.glide.Glide;
import com.example.myshop.R;
import com.example.myshop.model.Category;
import com.example.myshop.network.RetrofitClient;

import java.util.List;
import java.util.Locale;

public class HomeCategoryAdapter extends RecyclerView.Adapter<HomeCategoryAdapter.CategoryViewHolder> {
    private List<Category> categories;
    private final OnCategoryClickListener clickListener;

    public interface OnCategoryClickListener {
        void onCategoryClick(Category category);
    }

    public HomeCategoryAdapter(List<Category> categories, OnCategoryClickListener clickListener) {
        this.categories = categories;
        this.clickListener = clickListener;
    }

    @NonNull
    @Override
    public CategoryViewHolder onCreateViewHolder(@NonNull ViewGroup parent, int viewType) {
        View view = LayoutInflater.from(parent.getContext()).inflate(R.layout.item_home_category, parent, false);
        return new CategoryViewHolder(view);
    }

    @Override
    public void onBindViewHolder(@NonNull CategoryViewHolder holder, int position) {
        Category category = categories.get(position);
        String displayName = category.getDisplayName();
        holder.nameText.setText(displayName);
        bindImage(holder, category, displayName);
        holder.itemView.setOnClickListener(view -> {
            if (clickListener != null) {
                clickListener.onCategoryClick(category);
            }
        });
    }

    @Override
    public int getItemCount() {
        return categories == null ? 0 : categories.size();
    }

    public void setCategories(List<Category> categories) {
        this.categories = categories;
        notifyDataSetChanged();
    }

    private void bindImage(CategoryViewHolder holder, Category category, String displayName) {
        String imageUrl = buildImageUrl(category.getImageUrl());
        int fallback = placeholderFor(displayName);
        if (imageUrl == null) {
            holder.imageView.setImageResource(fallback);
            return;
        }

        Glide.with(holder.itemView.getContext())
                .load(imageUrl)
                .placeholder(fallback)
                .error(fallback)
                .centerCrop()
                .into(holder.imageView);
    }

    private int placeholderFor(String categoryName) {
        String value = categoryName == null ? "" : categoryName.toLowerCase(Locale.US);
        if (value.contains("jewel") || value.contains("ring") || value.contains("gold")) {
            return R.drawable.ic_category_jewellery;
        }
        if (value.contains("beauty") || value.contains("skin") || value.contains("makeup") || value.contains("cosmetic")) {
            return R.drawable.ic_category_beauty;
        }
        if (value.contains("women") || value.contains("female") || value.contains("ladies")) {
            return R.drawable.ic_category_women;
        }
        if (value.contains("men") || value.contains("male")) {
            return R.drawable.ic_category_men;
        }
        return R.drawable.ic_category_fashion;
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

    static class CategoryViewHolder extends RecyclerView.ViewHolder {
        private final ImageView imageView;
        private final TextView nameText;

        CategoryViewHolder(@NonNull View itemView) {
            super(itemView);
            imageView = itemView.findViewById(R.id.homeCategoryImageView);
            nameText = itemView.findViewById(R.id.homeCategoryNameText);
        }
    }
}
