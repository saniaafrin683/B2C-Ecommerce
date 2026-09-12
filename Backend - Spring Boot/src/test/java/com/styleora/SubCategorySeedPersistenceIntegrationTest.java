package com.styleora;

import com.styleora.dao.CategoryDao;
import com.styleora.model.Category;
import com.styleora.model.SubCategory;
import com.styleora.service.SubCategorySeedService;
import com.styleora.service.SubCategoryService;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.transaction.annotation.Transactional;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNull;

@SpringBootTest
@Transactional
class SubCategorySeedPersistenceIntegrationTest {

    @Autowired
    private SubCategoryService subCategoryService;

    @Autowired
    private SubCategorySeedService subCategorySeedService;

    @Autowired
    private CategoryDao categoryDao;

    @Test
    void rerunningSeedDoesNotReinsertWhenSubCategoryTableAlreadyHasData() {
        subCategorySeedService.run();
        long beforeCount = subCategoryService.countAllSubCategories();

        subCategorySeedService.run();

        long afterCount = subCategoryService.countAllSubCategories();
        assertEquals(beforeCount, afterCount);
    }

    @Test
    void deletedUnusedSubCategoryDoesNotReturnAfterSeedRerun() {
        long uniqueSuffix = System.currentTimeMillis();

        Category category = new Category();
        category.setCategoryTitle("SubCategory Seed Test " + uniqueSuffix);
        category.setCreatedBy("Admin");
        category.setStock(0);
        category.setTagId("CAT_SUB_SEED_TEST_" + uniqueSuffix);
        category.setDescription("Sub category seed persistence test");
        category.setImageUrl("");
        category = categoryDao.saveCategory(category);

        SubCategory subCategory = new SubCategory();
        subCategory.setSubCategoryCode("SC_SUB_SEED_TEST");
        subCategory.setSubCategoryName("Sub Seed Test " + uniqueSuffix);
        subCategory.setCategoryId(category.getId());
        subCategory.setCreatedBy("Admin");
        subCategory.setStock(0);
        subCategory.setTagId("TAG_SUB_SEED_TEST_" + uniqueSuffix);
        subCategory.setDescription("Sub category seed persistence item");
        subCategory.setImageUrl("");
        subCategory.setStatus("Active");
        subCategory = subCategoryService.saveSubCategory(subCategory);

        Long deletedId = subCategory.getId();
        subCategoryService.deleteSubCategory(deletedId);
        assertNull(subCategoryService.getSubCategoryById(deletedId));

        subCategorySeedService.run();

        assertNull(subCategoryService.getSubCategoryById(deletedId));
    }
}
