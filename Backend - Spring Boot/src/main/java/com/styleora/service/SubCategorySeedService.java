package com.styleora.service;

import java.util.List;
import java.util.Map;

import org.springframework.boot.CommandLineRunner;
import org.springframework.stereotype.Service;

import com.styleora.model.Category;
import com.styleora.model.SubCategory;

@Service
public class SubCategorySeedService implements CommandLineRunner {

    private final CategoryService categoryService;
    private final SubCategoryService subCategoryService;

    public SubCategorySeedService(CategoryService categoryService, SubCategoryService subCategoryService) {
        this.categoryService = categoryService;
        this.subCategoryService = subCategoryService;
    }

    @Override
    public void run(String... args) {
        if (subCategoryService.countAllSubCategories() > 0) {
            return;
        }

        Map<String, List<String>> categorySubCategories = Map.ofEntries(
                Map.entry("Fish & Meat", List.of("Sea fish", "River fish", "Pond fish")),
                Map.entry("Sports & Outdoors", List.of(
                        "Exercise & Fitness",
                        "Treadmills",
                        "Exercise Bikes",
                        "Dumbbells",
                        "Cycling",
                        "Boxing & Martial Arts",
                        "Shoes & Clothing",
                        "Fan Shop",
                        "Team Sports",
                        "Shoe"
                )),
                Map.entry("Vegetable", List.of("Fresh Vegetables", "Leafy Vegetables", "Root Vegetables")),
                Map.entry("Mother & Baby", List.of("Baby Care", "Baby Food", "Mother Care")),
                Map.entry("Home & Lifestyle", List.of("Home Decor", "Kitchen & Dining", "Furniture")),
                Map.entry("Groceries", List.of("Rice & Grains", "Spices", "Oil & Ghee")),
                Map.entry("Electronic Accessories", List.of("Mobile Accessories", "Computer Accessories", "Chargers & Cables")),
                Map.entry("TV & Home Appliances", List.of("Television", "Refrigerator", "Washing Machine")),
                Map.entry("Electronics Devices", List.of("Cameras", "Gadgets", "Smart Devices")),
                Map.entry("Men & Boys Fashion", List.of("Clothing", "Shoes", "Accessories")),
                Map.entry("Women And Girls Fashion", List.of("Hijabs", "Clothing", "Shoes", "Bags")),
                Map.entry("Watches, Bags, Jewellery", List.of("Watches", "Bags", "Jewellery")),
                Map.entry("Health & Beauty", List.of("Skin Care", "Hair Care", "Beauty Tools")),
                Map.entry("Electronics", List.of("Phone", "Laptop", "Tablet"))
        );

        for (Map.Entry<String, List<String>> entry : categorySubCategories.entrySet()) {
            Category category = categoryService.findByCategoryTitle(entry.getKey());

            if (category == null || category.getId() == null) {
                continue;
            }

            for (String subCategoryName : entry.getValue()) {
                if (subCategoryService.existsByNameAndCategoryId(subCategoryName, category.getId())) {
                    continue;
                }

                SubCategory subCategory = new SubCategory();
                subCategory.setSubCategoryCode(buildCode(subCategoryName));
                subCategory.setSubCategoryName(subCategoryName);
                subCategory.setCategoryId(category.getId());
                subCategory.setCategoryName(category.getCategoryTitle());
                subCategory.setCreatedBy("Admin");
                subCategory.setStock(0);
                subCategory.setTagId(buildTagId(category.getCategoryTitle(), subCategoryName));
                subCategory.setDescription(subCategoryName + " under " + category.getCategoryTitle());
                subCategory.setImageUrl(null);
                subCategory.setStatus("Active");

                subCategoryService.saveSubCategory(subCategory);
            }
        }
    }

    private String buildCode(String subCategoryName) {
        return "SC_" + normalize(subCategoryName);
    }

    private String buildTagId(String categoryName, String subCategoryName) {
        return "TAG_" + normalize(categoryName) + "_" + normalize(subCategoryName);
    }

    private String normalize(String value) {
        return value
                .toUpperCase()
                .replace("&", "AND")
                .replace(",", "")
                .replaceAll("[^A-Z0-9]+", "_")
                .replaceAll("^_+|_+$", "");
    }
}
