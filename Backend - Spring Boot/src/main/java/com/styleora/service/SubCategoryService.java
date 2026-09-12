package com.styleora.service;

import com.styleora.dao.SubCategoryDao;
import com.styleora.dao.CategoryDao;
import com.styleora.dao.ProductDao;
import com.styleora.model.Category;
import com.styleora.model.SubCategory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

import java.util.List;

@Service
public class SubCategoryService {

    @Autowired
    private SubCategoryDao subCategoryDao;

    @Autowired
    private CategoryDao categoryDao;

    @Autowired
    private ProductDao productDao;

    public SubCategory saveSubCategory(SubCategory subCategory) {
        subCategory.setId(null);
        applyCategoryHierarchy(subCategory);
        return subCategoryDao.saveSubCategory(subCategory);
    }

    public List<SubCategory> getAllSubCategories() {
        return subCategoryDao.getAllSubCategories();
    }

    public long countAllSubCategories() {
        return subCategoryDao.countAll();
    }

    public SubCategory getSubCategoryById(Long id) {
        return subCategoryDao.getSubCategoryById(id);
    }

    public List<SubCategory> getSubCategoriesByCategoryId(Long categoryId) {
        return subCategoryDao.getSubCategoriesByCategoryId(categoryId);
    }

    public boolean existsByNameAndCategoryId(String subCategoryName, Long categoryId) {
        return subCategoryDao.existsByNameAndCategoryId(subCategoryName, categoryId);
    }

    public SubCategory updateSubCategory(Long id, SubCategory updatedSubCategory) {
        SubCategory existingSubCategory = subCategoryDao.getSubCategoryById(id);

        if (existingSubCategory == null) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "Sub category not found");
        }

        updatedSubCategory.setId(existingSubCategory.getId());
        updatedSubCategory.setCreatedAt(existingSubCategory.getCreatedAt());
        applyCategoryHierarchy(updatedSubCategory);

        return subCategoryDao.updateSubCategory(id, updatedSubCategory);
    }

    public boolean deleteSubCategory(Long id) {
        SubCategory existingSubCategory = subCategoryDao.getSubCategoryById(id);

        if (existingSubCategory == null) {
            return false;
        }

        if (productDao.countBySubCategoryId(id) > 0) {
            throw new ResponseStatusException(
                    HttpStatus.CONFLICT,
                    "Cannot delete sub category because products are using it."
            );
        }

        subCategoryDao.deleteSubCategory(id);
        return true;
    }

    private void applyCategoryHierarchy(SubCategory subCategory) {
        Long categoryId = subCategory.getCategoryId();

        if (categoryId == null) {
            subCategory.setCategoryName("");
            return;
        }

        Category category = categoryDao.getCategoryById(categoryId);
        if (category == null) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Selected category does not exist");
        }

        subCategory.setCategoryName(category.getCategoryTitle());
    }
}
