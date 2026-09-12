package com.styleora.service;

import com.styleora.dao.ProductDao;
import com.styleora.dao.SubCategoryDao;
import com.styleora.dto.ProductPageResponse;
import com.styleora.dto.ProductStockAdjustmentRequest;
import com.styleora.dto.ProductStockAdjustmentResponse;
import com.styleora.dto.ProductUploadRequest;
import com.styleora.model.Product;
import com.styleora.model.SubCategory;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.util.StringUtils;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.web.server.ResponseStatusException;

import java.io.IOException;
import java.math.BigDecimal;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.StandardCopyOption;
import java.util.List;
import java.util.UUID;

@Service
public class ProductService {

    private static final Path PRODUCT_IMAGE_UPLOAD_DIR = Paths.get("uploads", "product-images");
    private static final Logger LOGGER = LoggerFactory.getLogger(ProductService.class);
    private static final long MAX_FILE_SIZE = 5 * 1024 * 1024; // 5MB
    private static final String[] ALLOWED_CONTENT_TYPES = {
        "image/jpeg",
        "image/jpg",
        "image/png",
        "image/gif",
        "image/webp"
    };
    private static final String[] ALLOWED_EXTENSIONS = {
        ".jpg", ".jpeg", ".png", ".gif", ".webp"
    };

    @Autowired
    private ProductDao productDao;

    @Autowired
    private SubCategoryDao subCategoryDao;

    public Product saveProduct(Product product) {
        normalizeProduct(product);
        return productDao.saveProduct(product);
    }

    public Product saveProductWithUpload(ProductUploadRequest request) {
        Product product = mapUploadRequest(request, new Product());
        return saveProduct(product);
    }

    public List<Product> getAllProducts() {
        return productDao.getAllProducts();
    }

    public List<Product> getProductsBySubCategoryId(Long subCategoryId) {
        return productDao.getProductsBySubCategoryId(subCategoryId);
    }

    public ProductPageResponse getProductsPage(int page, int size, String sortBy, String sortDir) {
        int normalizedPage = Math.max(page, 0);
        int normalizedSize = normalizePageSize(size);
        long totalElements = productDao.countAllProducts();

        ProductPageResponse response = new ProductPageResponse();
        response.setContent(productDao.getProductsPage(normalizedPage, normalizedSize, sortBy, sortDir));
        response.setTotalElements(totalElements);
        response.setPage(normalizedPage);
        response.setSize(normalizedSize);
        response.setSortBy(sortBy);
        response.setSortDir(sortDir);
        response.setTotalPages((int) Math.ceil(totalElements / (double) normalizedSize));
        return response;
    }

    public ProductPageResponse searchProducts(
            String query,
            String category,
            String brand,
            String gender,
            String tag,
            BigDecimal minPrice,
            BigDecimal maxPrice,
            int page,
            int size,
            String sortBy,
            String sortDir
    ) {
        int normalizedPage = Math.max(page, 0);
        int normalizedSize = normalizePageSize(size);
        long totalElements = productDao.countSearchProducts(query, category, brand, gender, tag, minPrice, maxPrice);

        ProductPageResponse response = new ProductPageResponse();
        response.setContent(productDao.searchProducts(
                query,
                category,
                brand,
                gender,
                tag,
                minPrice,
                maxPrice,
                normalizedPage,
                normalizedSize,
                sortBy,
                sortDir
        ));
        response.setTotalElements(totalElements);
        response.setPage(normalizedPage);
        response.setSize(normalizedSize);
        response.setSortBy(sortBy);
        response.setSortDir(sortDir);
        response.setTotalPages((int) Math.ceil(totalElements / (double) normalizedSize));
        return response;
    }

    public List<Product> getLowStockProducts() {
        return productDao.getLowStockProducts();
    }

    public Product getProductById(Long id) {
        return productDao.getProductById(id);
    }

    public ProductStockAdjustmentResponse reserveStock(Long productId, Integer requestedQuantity) {
        int quantity = normalizeRequestedQuantity(requestedQuantity);
        Product product = productDao.getProductById(productId);

        if (product == null) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "Product not found.");
        }

        int availableStock = normalizeStock(product.getStock());

        if (availableStock <= 0) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Product is out of stock.");
        }

        if (quantity > availableStock) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST,
                    product.getName() + " has only " + availableStock + " item(s) left in stock."
            );
        }

        boolean updated = productDao.reduceStock(productId, quantity);

        if (!updated) {
            Product refreshedProduct = productDao.getProductById(productId);
            int refreshedStock = normalizeStock(refreshedProduct != null ? refreshedProduct.getStock() : 0);

            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST,
                    product.getName() + " has only " + refreshedStock + " item(s) left in stock."
            );
        }

        Product updatedProduct = productDao.getProductById(productId);

        return new ProductStockAdjustmentResponse(
                productId,
                quantity,
                normalizeStock(updatedProduct != null ? updatedProduct.getStock() : 0),
                "Stock reserved successfully."
        );
    }

    public ProductStockAdjustmentResponse releaseStock(Long productId, Integer requestedQuantity) {
        int quantity = normalizeRequestedQuantity(requestedQuantity);
        Product product = productDao.getProductById(productId);

        if (product == null) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "Product not found.");
        }

        boolean updated = productDao.increaseStock(productId, quantity);

        if (!updated) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Unable to release stock for this product.");
        }

        Product updatedProduct = productDao.getProductById(productId);

        return new ProductStockAdjustmentResponse(
                productId,
                quantity,
                normalizeStock(updatedProduct != null ? updatedProduct.getStock() : 0),
                "Stock released successfully."
        );
    }

    public Product updateProduct(Long id, Product updatedProduct) {
        Product existingProduct = productDao.getProductById(id);

        if (existingProduct == null) {
            return null;
        }

        LOGGER.info(
                "Updating product id={} existingPrice={} incomingPrice={} existingDiscount={} incomingDiscount={} existingTax={} incomingTax={} existingStock={} incomingStock={}",
                id,
                existingProduct.getPrice(),
                updatedProduct.getPrice(),
                existingProduct.getDiscount(),
                updatedProduct.getDiscount(),
                existingProduct.getTax(),
                updatedProduct.getTax(),
                existingProduct.getStock(),
                updatedProduct.getStock()
        );

        copyProductFields(existingProduct, updatedProduct);

        Product savedProduct = productDao.updateProduct(existingProduct);
        return productDao.getProductById(savedProduct.getId());
    }

    public Product updateProductWithUpload(Long id, ProductUploadRequest request) {
        Product existingProduct = productDao.getProductById(id);

        if (existingProduct == null) {
            return null;
        }

        LOGGER.info(
                "Updating product with upload id={} existingPrice={} incomingPrice={} existingDiscount={} incomingDiscount={} existingTax={} incomingTax={} existingStock={} incomingStock={}",
                id,
                existingProduct.getPrice(),
                request.getPrice(),
                existingProduct.getDiscount(),
                request.getDiscount(),
                existingProduct.getTax(),
                request.getTax(),
                existingProduct.getStock(),
                request.getStock()
        );

        Product mappedProduct = mapUploadRequest(request, existingProduct);
        Product savedProduct = productDao.updateProduct(mappedProduct);

        return productDao.getProductById(savedProduct.getId());
    }

    public boolean deleteProduct(Long id) {
        Product existingProduct = productDao.getProductById(id);

        if (existingProduct == null) {
            return false;
        }

        try {
            productDao.deleteProduct(id);
            return true;
        } catch (DataIntegrityViolationException ex) {
            throw new ResponseStatusException(
                    HttpStatus.CONFLICT,
                    "Cannot delete product because it is used in orders, purchases, reviews, inventory, shipment, return, or other business records."
            );
        } catch (Exception ex) {
            throw new ResponseStatusException(
                    HttpStatus.CONFLICT,
                    "Cannot delete product because it is linked with existing business records."
            );
        }
    }

    private Product mapUploadRequest(ProductUploadRequest request, Product target) {
        target.setName(request.getName());
        target.setCategory(request.getCategory());
        target.setSubCategoryId(request.getSubCategoryId());
        target.setSubCategory(request.getSubCategory());
        target.setBrand(request.getBrand());
        target.setWeight(request.getWeight());
        target.setGender(request.getGender());
        target.setDescription(request.getDescription());
        target.setTagNumber(request.getTagNumber());
        target.setStock(request.getStock());
        target.setTag(request.getTag());
        target.setPrice(request.getPrice());
        target.setDiscount(request.getDiscount());
        target.setTax(request.getTax());
        target.setImageUrl(resolveImageUrl(request.getImageFile(), request.getImageUrl(), target.getImageUrl()));

        normalizeProduct(target);

        return target;
    }

    private void copyProductFields(Product target, Product source) {
        target.setName(source.getName());
        target.setCategory(source.getCategory());
        target.setSubCategoryId(source.getSubCategoryId());
        target.setSubCategory(source.getSubCategory());
        target.setBrand(source.getBrand());
        target.setWeight(source.getWeight());
        target.setGender(source.getGender());
        target.setDescription(source.getDescription());
        target.setTagNumber(source.getTagNumber());
        target.setStock(source.getStock());
        target.setTag(source.getTag());
        target.setPrice(source.getPrice());
        target.setDiscount(source.getDiscount());
        target.setTax(source.getTax());
        target.setImageUrl(source.getImageUrl());

        normalizeProduct(target);
    }

    private String resolveImageUrl(MultipartFile imageFile, String imageUrl, String existingImageUrl) {
        if (imageFile != null && !imageFile.isEmpty()) {
            return storeImage(imageFile);
        }

        if (StringUtils.hasText(imageUrl)) {
            return imageUrl.trim();
        }

        return existingImageUrl;
    }

    private String storeImage(MultipartFile imageFile) {
        String originalFileName = imageFile.getOriginalFilename();

        // Validate file size
        if (imageFile.getSize() > MAX_FILE_SIZE) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST,
                "File size exceeds maximum allowed size of 5MB");
        }

        // Validate content type
        String contentType = imageFile.getContentType();
        if (contentType == null || !isAllowedContentType(contentType)) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST,
                "Invalid file type. Only JPG, PNG, GIF, and WEBP are allowed");
        }

        // Validate file extension
        String extension = resolveExtension(originalFileName);
        if (!isAllowedExtension(extension)) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST,
                "Invalid file extension. Only JPG, PNG, GIF, and WEBP are allowed");
        }

        String fileName = UUID.randomUUID() + extension;

        try {
            Files.createDirectories(PRODUCT_IMAGE_UPLOAD_DIR);
            Path targetPath = PRODUCT_IMAGE_UPLOAD_DIR.resolve(fileName).normalize();

            // Security: Ensure the path is within the upload directory
            if (!targetPath.startsWith(PRODUCT_IMAGE_UPLOAD_DIR.toAbsolutePath())) {
                throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Invalid file path");
            }

            Files.copy(imageFile.getInputStream(), targetPath, StandardCopyOption.REPLACE_EXISTING);

            return "/uploads/product-images/" + fileName;
        } catch (IOException ex) {
            LOGGER.error("Failed to store product image", ex);
            throw new ResponseStatusException(HttpStatus.INTERNAL_SERVER_ERROR, "Failed to store product image.");
        }
    }

    private boolean isAllowedContentType(String contentType) {
        for (String allowed : ALLOWED_CONTENT_TYPES) {
            if (allowed.equalsIgnoreCase(contentType)) {
                return true;
            }
        }
        return false;
    }

    private boolean isAllowedExtension(String extension) {
        if (extension == null) {
            return false;
        }
        String lowerExtension = extension.toLowerCase();
        for (String allowed : ALLOWED_EXTENSIONS) {
            if (allowed.equals(lowerExtension)) {
                return true;
            }
        }
        return false;
    }

    private String resolveExtension(String fileName) {
        if (!StringUtils.hasText(fileName) || !fileName.contains(".")) {
            return ".png";
        }

        return fileName.substring(fileName.lastIndexOf('.'));
    }

    private int normalizePageSize(int size) {
        if (size <= 0) {
            return 12;
        }

        return Math.min(size, 100);
    }

    private int normalizeRequestedQuantity(Integer quantity) {
        int normalizedQuantity = quantity == null ? 0 : quantity;

        if (normalizedQuantity <= 0) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Quantity must be at least 1.");
        }

        return normalizedQuantity;
    }

    private int normalizeStock(Integer stock) {
        return stock == null ? 0 : Math.max(stock, 0);
    }

    private void normalizeProduct(Product product) {
        if (product == null) {
            return;
        }

        product.setName(trimToNull(product.getName()));
        product.setCategory(trimToNull(product.getCategory()));
        product.setSubCategory(trimToNull(product.getSubCategory()));
        product.setBrand(trimToNull(product.getBrand()));
        product.setWeight(trimToNull(product.getWeight()));
        product.setGender(trimToNull(product.getGender()));
        product.setDescription(trimToNull(product.getDescription()));
        product.setTagNumber(trimToNull(product.getTagNumber()));
        product.setTag(trimToNull(product.getTag()));
        product.setImageUrl(trimToNull(product.getImageUrl()));

        if (product.getStock() == null || product.getStock() < 0) {
            product.setStock(0);
        }

        alignProductHierarchy(product);
    }

    private String trimToNull(String value) {
        if (!StringUtils.hasText(value)) {
            return null;
        }

        return value.trim();
    }

    private void alignProductHierarchy(Product product) {
        Long subCategoryId = product.getSubCategoryId();

        if (subCategoryId == null) {
            product.setSubCategory(trimToNull(product.getSubCategory()));
            return;
        }

        SubCategory subCategory = subCategoryDao.getSubCategoryById(subCategoryId);

        if (subCategory == null) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Selected sub category does not exist.");
        }

        String categoryName = trimToNull(product.getCategory());
        String parentCategoryName = trimToNull(subCategory.getCategoryName());

        if (categoryName == null) {
            product.setCategory(parentCategoryName);
        } else if (parentCategoryName != null && !categoryName.equalsIgnoreCase(parentCategoryName)) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST,
                    "Selected sub category does not belong to the selected category."
            );
        }

        product.setSubCategory(subCategory.getSubCategoryName());
    }
}
