package com.styleora.service;

import java.util.List;

import org.springframework.boot.CommandLineRunner;
import org.springframework.stereotype.Service;

import com.styleora.model.Category;

@Service
public class CategorySeedService implements CommandLineRunner {

    private final CategoryService categoryService;

    public CategorySeedService(CategoryService categoryService) {
        this.categoryService = categoryService;
    }

    @Override
    public void run(String... args) {
        if (categoryService.countAllCategories() > 0) {
            return;
        }

        List<String> categoryTitles = List.of(
                "Vegetable",
                "Mother & Baby",
                "Fish & Meat",
                "Sports & Outdoors",
                "Home & Lifestyle",
                "Groceries",
                "Electronic Accessories",
                "TV & Home Appliances",
                "Electronics Devices",
                "Men & Boys Fashion",
                "Watches, Bags, Jewellery",
                "Health & Beauty",
                "Electronics",
                "Women And Girls Fashion"
        );

        for (String categoryTitle : categoryTitles) {
            Category category = new Category();
            category.setCategoryTitle(categoryTitle);
            category.setCreatedBy("System Seed");
            category.setStock(0);
            category.setTagId(buildTagId(categoryTitle));
            category.setDescription(categoryTitle + " category");
            category.setImageUrl("");

            categoryService.saveCategory(category);
        }
    }

    private String buildTagId(String categoryTitle) {
        String normalized = categoryTitle
                .toUpperCase()
                .replace("&", "AND")
                .replace(",", "")
                .replaceAll("[^A-Z0-9]+", "_")
                .replaceAll("^_+|_+$", "");

        return "CAT_" + normalized;
    }
}
