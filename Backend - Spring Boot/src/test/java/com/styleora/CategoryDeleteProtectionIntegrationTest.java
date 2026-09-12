package com.styleora;

import com.styleora.dao.CategoryDao;
import com.styleora.model.Category;
import com.styleora.model.Product;
import com.styleora.model.SubCategory;
import com.styleora.service.CategoryService;
import com.styleora.service.ProductService;
import com.styleora.service.SubCategoryService;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import java.math.BigDecimal;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

@SpringBootTest
@Transactional
class CategoryDeleteProtectionIntegrationTest {

    @Autowired
    private CategoryDao categoryDao;

    @Autowired
    private CategoryService categoryService;

    @Autowired
    private SubCategoryService subCategoryService;

    @Autowired
    private ProductService productService;

    @Test
    void deleteCategoryBlocksWhenSubCategoriesReferenceIt() {
        Category category = createCategory("Delete Guard Sub " + System.currentTimeMillis());

        SubCategory subCategory = new SubCategory();
        subCategory.setSubCategoryCode("SC_DEL_GUARD_SUB");
        subCategory.setSubCategoryName("Delete Guard Sub Category " + System.currentTimeMillis());
        subCategory.setCategoryId(category.getId());
        subCategory.setCreatedBy("Admin");
        subCategory.setStock(0);
        subCategory.setTagId("TAG_DEL_GUARD_SUB");
        subCategory.setDescription("Delete guard sub category");
        subCategory.setImageUrl("");
        subCategory.setStatus("Active");
        subCategoryService.saveSubCategory(subCategory);

        ResponseStatusException exception = assertThrows(
                ResponseStatusException.class,
                () -> categoryService.deleteCategory(category.getId())
        );

        assertEquals(409, exception.getStatusCode().value());
        assertEquals("Cannot delete category because products or subcategories are using it.", exception.getReason());
    }

    @Test
    void deleteCategoryBlocksWhenProductsReferenceIt() {
        long uniqueSuffix = System.currentTimeMillis();
        Category category = createCategory("Delete Guard Product " + uniqueSuffix);

        Product product = new Product();
        product.setName("Delete Guard Product " + uniqueSuffix);
        product.setCategory(category.getCategoryTitle());
        product.setSubCategoryId(null);
        product.setSubCategory("");
        product.setBrand("Styleora");
        product.setWeight("1kg");
        product.setGender("Unisex");
        product.setDescription("Delete guard product");
        product.setTagNumber("SKU-" + uniqueSuffix);
        product.setStock(1);
        product.setTag("Featured");
        product.setPrice(BigDecimal.valueOf(100));
        product.setDiscount(BigDecimal.ZERO);
        product.setTax(BigDecimal.ZERO);
        product.setImageUrl("");
        productService.saveProduct(product);

        ResponseStatusException exception = assertThrows(
                ResponseStatusException.class,
                () -> categoryService.deleteCategory(category.getId())
        );

        assertEquals(409, exception.getStatusCode().value());
        assertEquals("Cannot delete category because products or subcategories are using it.", exception.getReason());
    }

    private Category createCategory(String title) {
        Category category = new Category();
        category.setCategoryTitle(title);
        category.setCreatedBy("Admin");
        category.setStock(0);
        category.setTagId("TAG_" + title.replaceAll("[^A-Za-z0-9]+", "_"));
        category.setDescription("Delete protection test category");
        category.setImageUrl("");
        return categoryDao.saveCategory(category);
    }
}
