package com.styleora;

import com.styleora.dao.CategoryDao;
import com.styleora.model.Category;
import com.styleora.service.CategorySeedService;
import com.styleora.service.CategoryService;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.transaction.annotation.Transactional;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNull;

@SpringBootTest
@Transactional
class CategorySeedPersistenceIntegrationTest {

    @Autowired
    private CategoryService categoryService;

    @Autowired
    private CategorySeedService categorySeedService;

    @Autowired
    private CategoryDao categoryDao;

    @Test
    void rerunningSeedDoesNotReinsertWhenCategoryTableAlreadyHasData() {
        long beforeCount = categoryService.countAllCategories();

        categorySeedService.run();

        long afterCount = categoryService.countAllCategories();
        assertEquals(beforeCount, afterCount);
    }

    @Test
    void deletedUnusedCategoryDoesNotReturnAfterSeedRerun() {
        long uniqueSuffix = System.currentTimeMillis();

        Category category = new Category();
        category.setCategoryTitle("Category Seed Test " + uniqueSuffix);
        category.setCreatedBy("Admin");
        category.setStock(0);
        category.setTagId("CAT_SEED_TEST_" + uniqueSuffix);
        category.setDescription("Category seed persistence test");
        category.setImageUrl("");
        category = categoryDao.saveCategory(category);

        Long deletedId = category.getId();
        categoryService.deleteCategory(deletedId);
        assertNull(categoryService.getCategoryById(deletedId));

        categorySeedService.run();

        assertNull(categoryService.getCategoryById(deletedId));
    }
}
