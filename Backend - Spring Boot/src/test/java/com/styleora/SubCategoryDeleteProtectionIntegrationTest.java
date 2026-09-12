package com.styleora;

import com.styleora.dao.CategoryDao;
import com.styleora.model.Category;
import com.styleora.model.Product;
import com.styleora.model.SubCategory;
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
class SubCategoryDeleteProtectionIntegrationTest {

    @Autowired
    private CategoryDao categoryDao;

    @Autowired
    private SubCategoryService subCategoryService;

    @Autowired
    private ProductService productService;

    @Test
    void deleteSubCategoryBlocksWhenProductsReferenceIt() {
        long uniqueSuffix = System.currentTimeMillis();

        Category category = new Category();
        category.setCategoryTitle("Sub Delete Guard " + uniqueSuffix);
        category.setCreatedBy("Admin");
        category.setStock(0);
        category.setTagId("CAT_SUB_DELETE_GUARD_" + uniqueSuffix);
        category.setDescription("Sub category delete protection category");
        category.setImageUrl("");
        category = categoryDao.saveCategory(category);

        SubCategory subCategory = new SubCategory();
        subCategory.setSubCategoryCode("SC_SUB_DELETE_GUARD");
        subCategory.setSubCategoryName("Sub Delete Guard Item " + uniqueSuffix);
        subCategory.setCategoryId(category.getId());
        subCategory.setCreatedBy("Admin");
        subCategory.setStock(0);
        subCategory.setTagId("TAG_SUB_DELETE_GUARD_" + uniqueSuffix);
        subCategory.setDescription("Sub category delete protection item");
        subCategory.setImageUrl("");
        subCategory.setStatus("Active");
        subCategory = subCategoryService.saveSubCategory(subCategory);
        final Long subCategoryId = subCategory.getId();

        Product product = new Product();
        product.setName("Sub Delete Guard Product " + uniqueSuffix);
        product.setCategory(category.getCategoryTitle());
        product.setSubCategoryId(subCategoryId);
        product.setSubCategory(subCategory.getSubCategoryName());
        product.setBrand("Styleora");
        product.setWeight("1kg");
        product.setGender("Unisex");
        product.setDescription("Sub category delete protection product");
        product.setTagNumber("SKU-SUB-" + uniqueSuffix);
        product.setStock(1);
        product.setTag("Featured");
        product.setPrice(BigDecimal.valueOf(100));
        product.setDiscount(BigDecimal.ZERO);
        product.setTax(BigDecimal.ZERO);
        product.setImageUrl("");
        productService.saveProduct(product);

        ResponseStatusException exception = assertThrows(
                ResponseStatusException.class,
                () -> subCategoryService.deleteSubCategory(subCategoryId)
        );

        assertEquals(409, exception.getStatusCode().value());
        assertEquals("Cannot delete sub category because products are using it.", exception.getReason());
    }
}
