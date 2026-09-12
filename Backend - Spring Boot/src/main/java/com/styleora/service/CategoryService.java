package com.styleora.service;

import java.util.List;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

import com.styleora.dao.CategoryDao;
import com.styleora.dao.ProductDao;
import com.styleora.dao.SubCategoryDao;
import com.styleora.model.Category;

@Service
public class CategoryService {

    @Autowired
    private CategoryDao categoryDao;

    @Autowired
    private SubCategoryDao subCategoryDao;

    @Autowired
    private ProductDao productDao;

    public Category saveCategory(Category category) {
        category.setId(null);
        return categoryDao.saveCategory(category);
    }

    public List<Category> getAllCategories() {

        return categoryDao.getAllCategories();
    }

    public long countAllCategories() {
        return categoryDao.countAll();
    }

    public Category getCategoryById(Long id) {

        return categoryDao.getCategoryById(id);
    }

    public boolean existsByCategoryTitle(String categoryTitle) {
        return categoryDao.existsByCategoryTitle(categoryTitle);
    }

    public Category findByCategoryTitle(String categoryTitle) {
        return categoryDao.findByCategoryTitle(categoryTitle);
    }

    public Category updateCategory(Long id, Category updatedCategory) {

        Category existingCategory = categoryDao.getCategoryById(id);

        if (existingCategory == null) {
            return null;
        }

        existingCategory.setCategoryTitle(updatedCategory.getCategoryTitle());
        existingCategory.setCreatedBy(updatedCategory.getCreatedBy());
        existingCategory.setStock(updatedCategory.getStock());
        existingCategory.setTagId(updatedCategory.getTagId());
        existingCategory.setDescription(updatedCategory.getDescription());
        existingCategory.setImageUrl(updatedCategory.getImageUrl());

        return categoryDao.updateCategory(existingCategory);
    }

    public boolean deleteCategory(Long id) {

        Category existingCategory = categoryDao.getCategoryById(id);

        if (existingCategory == null) {
            return false;
        }

        long subCategoryCount = subCategoryDao.countByCategoryId(id);
        long productCount = productDao.countByCategoryName(existingCategory.getCategoryTitle());

        if (subCategoryCount > 0 || productCount > 0) {
            throw new ResponseStatusException(
                    HttpStatus.CONFLICT,
                    "Cannot delete category because products or subcategories are using it."
            );
        }

        categoryDao.deleteCategory(id);

        return true;
    }
}
