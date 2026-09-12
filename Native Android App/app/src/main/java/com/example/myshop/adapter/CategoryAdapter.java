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

import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;

public class CategoryAdapter extends RecyclerView.Adapter<RecyclerView.ViewHolder> {
    private static final int VIEW_TYPE_HEADER = 1;
    private static final int VIEW_TYPE_CATEGORY = 2;
    private static final List<String> SECTION_ORDER = Arrays.asList("Fashion", "Jewellery", "Beauty", "Men", "Women");

    private final List<Category> allCategories;
    private final List<Category> visibleCategories;
    private final List<Object> visibleItems = new ArrayList<>();
    private final OnCategoryClickListener clickListener;
    private Map<Long, Integer> subCategoryCounts = new HashMap<>();

    public interface OnCategoryClickListener {
        void onCategoryClick(Category category);
    }

    public CategoryAdapter(List<Category> categories, OnCategoryClickListener clickListener) {
        this.allCategories = new ArrayList<>(categories);
        this.visibleCategories = new ArrayList<>(categories);
        this.clickListener = clickListener;
        rebuildVisibleItems();
    }

    @NonNull
    @Override
    public RecyclerView.ViewHolder onCreateViewHolder(@NonNull ViewGroup parent, int viewType) {
        if (viewType == VIEW_TYPE_HEADER) {
            View view = LayoutInflater.from(parent.getContext()).inflate(R.layout.item_category_section, parent, false);
            return new SectionViewHolder(view);
        }
        View view = LayoutInflater.from(parent.getContext()).inflate(R.layout.item_category, parent, false);
        return new CategoryViewHolder(view);
    }

    @Override
    public void onBindViewHolder(@NonNull RecyclerView.ViewHolder holder, int position) {
        Object item = visibleItems.get(position);
        if (holder instanceof SectionViewHolder) {
            ((SectionViewHolder) holder).titleText.setText((String) item);
            return;
        }

        CategoryViewHolder categoryHolder = (CategoryViewHolder) holder;
        Category category = (Category) item;
        String displayName = category.getDisplayName();

        categoryHolder.nameText.setText(displayName);
        categoryHolder.countText.setText(buildCountText(category));
        bindImage(categoryHolder, category, displayName);

        categoryHolder.itemView.setOnClickListener(view -> {
            if (clickListener != null) {
                clickListener.onCategoryClick(category);
            }
        });
    }

    @Override
    public int getItemCount() {
        return visibleItems.size();
    }

    @Override
    public int getItemViewType(int position) {
        return visibleItems.get(position) instanceof String ? VIEW_TYPE_HEADER : VIEW_TYPE_CATEGORY;
    }

    public boolean isHeader(int position) {
        return getItemViewType(position) == VIEW_TYPE_HEADER;
    }

    public int getVisibleCategoryCount() {
        return visibleCategories.size();
    }

    public void setSubCategoryCounts(Map<Long, Integer> counts) {
        this.subCategoryCounts = counts == null ? new HashMap<>() : counts;
        notifyDataSetChanged();
    }

    public void filter(String query) {
        visibleCategories.clear();
        String normalizedQuery = query == null ? "" : query.trim().toLowerCase(Locale.US);
        if (normalizedQuery.isEmpty()) {
            visibleCategories.addAll(allCategories);
        } else {
            for (Category category : allCategories) {
                if (category.getDisplayName().toLowerCase(Locale.US).contains(normalizedQuery)) {
                    visibleCategories.add(category);
                }
            }
        }
        rebuildVisibleItems();
        notifyDataSetChanged();
    }

    private void rebuildVisibleItems() {
        visibleItems.clear();
        Map<String, List<Category>> groupedCategories = new HashMap<>();
        for (String section : SECTION_ORDER) {
            groupedCategories.put(section, new ArrayList<>());
        }
        for (Category category : visibleCategories) {
            groupedCategories.get(sectionFor(category.getDisplayName())).add(category);
        }
        for (String section : SECTION_ORDER) {
            List<Category> sectionCategories = groupedCategories.get(section);
            if (sectionCategories != null && !sectionCategories.isEmpty()) {
                visibleItems.add(section);
                visibleItems.addAll(sectionCategories);
            }
        }
    }

    private void bindImage(CategoryViewHolder holder, Category category, String displayName) {
        String imageUrl = buildImageUrl(category.getImageUrl());
        int fallbackDrawable = placeholderFor(displayName);
        if (imageUrl == null) {
            holder.imageView.setImageResource(fallbackDrawable);
            return;
        }

        holder.imageView.setVisibility(View.VISIBLE);
        Glide.with(holder.itemView.getContext())
                .load(imageUrl)
                .placeholder(fallbackDrawable)
                .error(fallbackDrawable)
                .centerCrop()
                .into(holder.imageView);
    }

    private String buildCountText(Category category) {
        Long categoryId = category.getId();
        Integer subCategoryCount = categoryId == null ? null : subCategoryCounts.get(categoryId);
        if (subCategoryCount != null && subCategoryCount > 0) {
            return subCategoryCount == 1 ? "1 collection" : subCategoryCount + " collections";
        }
        Integer stock = category.getStock();
        if (stock != null && stock > 0) {
            return stock == 1 ? "1 product" : stock + " products";
        }
        return "Explore products";
    }

    private String sectionFor(String categoryName) {
        String value = categoryName == null ? "" : categoryName.toLowerCase(Locale.US);
        if (value.contains("jewel") || value.contains("ring") || value.contains("gold")) {
            return "Jewellery";
        }
        if (value.contains("beauty") || value.contains("skin") || value.contains("makeup") || value.contains("cosmetic")) {
            return "Beauty";
        }
        if (value.contains("women") || value.contains("female") || value.contains("ladies")) {
            return "Women";
        }
        if (value.contains("men") || value.contains("male")) {
            return "Men";
        }
        return "Fashion";
    }

    private int placeholderFor(String categoryName) {
        String section = sectionFor(categoryName);
        if ("Jewellery".equals(section)) {
            return R.drawable.ic_category_jewellery;
        }
        if ("Beauty".equals(section)) {
            return R.drawable.ic_category_beauty;
        }
        if ("Men".equals(section)) {
            return R.drawable.ic_category_men;
        }
        if ("Women".equals(section)) {
            return R.drawable.ic_category_women;
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
        private final TextView countText;

        CategoryViewHolder(@NonNull View itemView) {
            super(itemView);
            imageView = itemView.findViewById(R.id.categoryImageView);
            nameText = itemView.findViewById(R.id.categoryNameText);
            countText = itemView.findViewById(R.id.categoryCountText);
        }
    }

    static class SectionViewHolder extends RecyclerView.ViewHolder {
        private final TextView titleText;

        SectionViewHolder(@NonNull View itemView) {
            super(itemView);
            titleText = itemView.findViewById(R.id.categorySectionTitleText);
        }
    }
}
