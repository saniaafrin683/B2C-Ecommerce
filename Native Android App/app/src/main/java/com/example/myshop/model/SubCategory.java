package com.example.myshop.model;

public class SubCategory {
    private Long id;
    private Long categoryId;
    private String subCategoryName;
    private String name;

    public Long getId() {
        return id;
    }

    public Long getCategoryId() {
        return categoryId;
    }

    public String getSubCategoryName() {
        return subCategoryName;
    }

    public String getName() {
        return name;
    }

    public String getDisplayName() {
        if (subCategoryName != null && !subCategoryName.trim().isEmpty()) {
            return subCategoryName;
        }
        if (name != null && !name.trim().isEmpty()) {
            return name;
        }
        return "Collection";
    }
}
