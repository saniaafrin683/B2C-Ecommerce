package com.styleora.controller;

import com.styleora.dto.ProductPageResponse;
import com.styleora.dto.ProductStockAdjustmentRequest;
import com.styleora.dto.ProductStockAdjustmentResponse;
import com.styleora.dto.ProductUploadRequest;
import com.styleora.model.Product;
import com.styleora.service.ProductService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.MediaType;
import org.springframework.web.bind.annotation.*;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.math.BigDecimal;
import java.util.List;

@RestController
@RequestMapping("/products")
public class ProductController {

    private static final Logger LOGGER = LoggerFactory.getLogger(ProductController.class);

    @Autowired
    private ProductService productService;

    @PostMapping("/create")
    public Product createProduct(@RequestBody Product product) {
        product.setId(null);
        return productService.saveProduct(product);
    }

    @PostMapping(value = "/create-upload", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public Product createProductWithUpload(@ModelAttribute ProductUploadRequest request) {
        return productService.saveProductWithUpload(request);
    }

    @GetMapping("/list")
    @Deprecated
    public List<Product> getAllProducts() {
        return productService.getAllProducts();
    }

    @GetMapping("/by-subcategory/{subCategoryId}")
    public List<Product> getProductsBySubCategory(@PathVariable Long subCategoryId) {
        return productService.getProductsBySubCategoryId(subCategoryId);
    }

    @GetMapping("/page")
    public ProductPageResponse getProductsPage(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "12") int size,
            @RequestParam(defaultValue = "id") String sortBy,
            @RequestParam(defaultValue = "desc") String sortDir
    ) {
        return productService.getProductsPage(page, size, sortBy, sortDir);
    }

    @GetMapping("/search")
    public ProductPageResponse searchProducts(
            @RequestParam(required = false) String query,
            @RequestParam(required = false) String category,
            @RequestParam(required = false) String brand,
            @RequestParam(required = false) String gender,
            @RequestParam(required = false) String tag,
            @RequestParam(required = false) BigDecimal minPrice,
            @RequestParam(required = false) BigDecimal maxPrice,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "12") int size,
            @RequestParam(defaultValue = "id") String sortBy,
            @RequestParam(defaultValue = "desc") String sortDir
    ) {
        return productService.searchProducts(query, category, brand, gender, tag, minPrice, maxPrice, page, size, sortBy, sortDir);
    }

    @GetMapping("/low-stock")
    public List<Product> getLowStockProducts() {
        return productService.getLowStockProducts();
    }

    @GetMapping("/{id}")
    public Product getProductById(@PathVariable Long id) {
        return productService.getProductById(id);
    }

    @PostMapping("/{id}/reserve-stock")
    public ProductStockAdjustmentResponse reserveStock(
            @PathVariable Long id,
            @RequestBody ProductStockAdjustmentRequest request
    ) {
        return productService.reserveStock(id, request != null ? request.getQuantity() : null);
    }

    @PostMapping("/{id}/release-stock")
    public ProductStockAdjustmentResponse releaseStock(
            @PathVariable Long id,
            @RequestBody ProductStockAdjustmentRequest request
    ) {
        return productService.releaseStock(id, request != null ? request.getQuantity() : null);
    }

    @PutMapping("/update/{id}")
    public Product updateProduct(@PathVariable Long id, @RequestBody Product product) {
        LOGGER.info("Product update request received id={}, price={}, discount={}, tax={}, stock={}",
                id, product.getPrice(), product.getDiscount(), product.getTax(), product.getStock());
        return productService.updateProduct(id, product);
    }

    @PutMapping(value = "/update-upload/{id}", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public Product updateProductWithUpload(@PathVariable Long id, @ModelAttribute ProductUploadRequest request) {
        LOGGER.info("Product update-upload request received id={}, price={}, discount={}, tax={}, stock={}",
                id, request.getPrice(), request.getDiscount(), request.getTax(), request.getStock());
        return productService.updateProductWithUpload(id, request);
    }

    @DeleteMapping("/delete/{id}")
    public String deleteProduct(@PathVariable Long id) {
        boolean deleted = productService.deleteProduct(id);

        if (deleted) {
            return "Product deleted successfully";
        } else {
            return "Product not found";
        }
    }
}
