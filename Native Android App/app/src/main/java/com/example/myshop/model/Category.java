package com.example.myshop.model;

public class Category {
    private Long id;
    private String categoryTitle;
    private String name;
    private String description;
    private String imageUrl;
    private Integer stock;

    public Long getId() {
        return id;
    }

    public String getCategoryTitle() {
        return categoryTitle;
    }

    public String getName() {
        return name;
    }

    public String getDescription() {
        return description;
    }

    public String getImageUrl() {
        return imageUrl;
    }

    public Integer getStock() {
        return stock;
    }

    public String getDisplayName() {
        if (categoryTitle != null && !categoryTitle.trim().isEmpty()) {
            return categoryTitle;
        }
        if (name != null && !name.trim().isEmpty()) {
            return name;
        }
        return "Category";
    }
}
