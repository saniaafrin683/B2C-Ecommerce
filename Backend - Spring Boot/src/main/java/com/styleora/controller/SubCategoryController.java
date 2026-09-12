package com.styleora.controller;

import com.styleora.model.SubCategory;
import com.styleora.service.SubCategoryService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequestMapping({"/subcategories", "/sub-categories"})
public class SubCategoryController {

    @Autowired
    private SubCategoryService subCategoryService;

    @PostMapping("/create")
    public SubCategory createSubCategory(@RequestBody SubCategory subCategory) {
        subCategory.setId(null);
        return subCategoryService.saveSubCategory(subCategory);
    }

    @GetMapping("/list")
    public List<SubCategory> getAllSubCategories() {
        return subCategoryService.getAllSubCategories();
    }

    @GetMapping("/by-category/{categoryId}")
    public List<SubCategory> getSubCategoriesByCategory(@PathVariable Long categoryId) {
        return subCategoryService.getSubCategoriesByCategoryId(categoryId);
    }

    @GetMapping("/{id}")
    public SubCategory getSubCategoryById(@PathVariable Long id) {
        return subCategoryService.getSubCategoryById(id);
    }

    @PutMapping("/update/{id}")
    public SubCategory updateSubCategory(
            @PathVariable Long id,
            @RequestBody SubCategory subCategory
    ) {
        return subCategoryService.updateSubCategory(id, subCategory);
    }

    @DeleteMapping("/delete/{id}")
    public String deleteSubCategory(@PathVariable Long id) {
        boolean deleted = subCategoryService.deleteSubCategory(id);

        if (deleted) {
            return "Sub category deleted successfully";
        }

        return "Sub category not found";
    }
}
