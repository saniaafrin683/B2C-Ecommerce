package com.styleora;

import com.styleora.dao.CategoryDao;
import com.styleora.model.Category;
import com.styleora.model.SubCategory;
import com.styleora.service.SubCategoryService;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

import static org.junit.jupiter.api.Assertions.assertNotNull;

@SpringBootTest
@Transactional
class SubCategoryServiceIntegrationTest {

    @Autowired
    private SubCategoryService subCategoryService;

    @Autowired
    private CategoryDao categoryDao;

    @Test
    void subCategoryReadAndSaveFlowWorks() {
        List<Category> categories = categoryDao.getAllCategories();
        Category category = categories.stream()
                .filter(item -> item.getId() != null)
                .findFirst()
                .orElseThrow();

        List<SubCategory> existingSubCategories = subCategoryService.getSubCategoriesByCategoryId(category.getId());
        assertNotNull(existingSubCategories);

        SubCategory subCategory = new SubCategory();
        subCategory.setSubCategoryCode("SC_TEST_FLOW");
        subCategory.setSubCategoryName("Test Flow " + System.currentTimeMillis());
        subCategory.setCategoryId(category.getId());
        subCategory.setCreatedBy("Admin");
        subCategory.setStock(0);
        subCategory.setTagId("TAG_TEST_FLOW");
        subCategory.setDescription("Integration test sub category");
        subCategory.setImageUrl("");
        subCategory.setStatus("Active");

        SubCategory savedSubCategory = subCategoryService.saveSubCategory(subCategory);
        assertNotNull(savedSubCategory.getId());
    }
}
