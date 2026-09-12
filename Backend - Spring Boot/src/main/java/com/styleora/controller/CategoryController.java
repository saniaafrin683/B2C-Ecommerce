package com.styleora.controller;

import java.util.List;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import com.styleora.model.Category;
import com.styleora.service.CategoryService;

@RestController
@RequestMapping("/categories")
public class CategoryController {

    @Autowired
    private CategoryService categoryService;

    @PostMapping("/create")
    public Category createCategory(@RequestBody Category category) {
        category.setId(null);
        return categoryService.saveCategory(category);
    }

    @GetMapping("/list")
    public List<Category> getAllCategories() {

        return categoryService.getAllCategories();
    }

    @GetMapping("/{id}")
    public Category getCategoryById(@PathVariable Long id) {

        return categoryService.getCategoryById(id);
    }

    @PutMapping("/update/{id}")
    public Category updateCategory(
            @PathVariable Long id,
            @RequestBody Category category
    ) {

        return categoryService.updateCategory(id, category);
    }

    @DeleteMapping("/delete/{id}")
    public String deleteCategory(@PathVariable Long id) {

        boolean deleted = categoryService.deleteCategory(id);

        if (deleted) {
            return "Category deleted successfully";
        } else {
            return "Category not found";
        }
    }
}
