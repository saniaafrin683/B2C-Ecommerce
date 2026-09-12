package com.styleora.dao;

import java.util.List;

import org.springframework.stereotype.Repository;

import com.styleora.model.Product;

import jakarta.persistence.EntityManager;
import jakarta.persistence.PersistenceContext;
import jakarta.persistence.TypedQuery;
import jakarta.transaction.Transactional;

import java.math.BigDecimal;
import java.util.HashMap;
import java.util.Map;

@Repository
@Transactional
public class ProductDao {

    @PersistenceContext
    private EntityManager entityManager;

    public Product saveProduct(Product product) {
        entityManager.persist(product);
        return product;
    }

    public List<Product> getAllProducts() {
        TypedQuery<Product> query = entityManager.createQuery(
                "SELECT p FROM Product p ORDER BY p.id DESC", Product.class);
        return query.getResultList();
    }

    public List<Product> getProductsBySubCategoryId(Long subCategoryId) {
        TypedQuery<Product> query = entityManager.createQuery(
                "SELECT p FROM Product p WHERE p.subCategoryId = :subCategoryId ORDER BY p.id DESC",
                Product.class
        );
        query.setParameter("subCategoryId", subCategoryId);
        return query.getResultList();
    }

    public List<Product> getProductsPage(int page, int size, String sortBy, String sortDir) {
        String orderBy = resolveSort(sortBy, sortDir);
        TypedQuery<Product> query = entityManager.createQuery(
                "SELECT p FROM Product p ORDER BY " + orderBy,
                Product.class
        );
        query.setFirstResult(page * size);
        query.setMaxResults(size);
        return query.getResultList();
    }

    public Long countAllProducts() {
        return toLong(entityManager.createQuery("SELECT COUNT(p) FROM Product p").getSingleResult());
    }

    public long countBySubCategoryId(Long subCategoryId) {
        if (subCategoryId == null) {
            return 0L;
        }

        Long count = entityManager.createQuery(
                "SELECT COUNT(p) FROM Product p WHERE p.subCategoryId = :subCategoryId",
                Long.class
        ).setParameter("subCategoryId", subCategoryId).getSingleResult();

        return count == null ? 0L : count;
    }

    public long countByCategoryName(String categoryName) {
        if (categoryName == null || categoryName.trim().isEmpty()) {
            return 0L;
        }

        Long count = entityManager.createQuery(
                "SELECT COUNT(p) FROM Product p WHERE LOWER(COALESCE(p.category, '')) = LOWER(:categoryName)",
                Long.class
        ).setParameter("categoryName", categoryName.trim()).getSingleResult();

        return count == null ? 0L : count;
    }

    public List<Product> searchProducts(String query, String category, String brand, String gender, String tag,
                                        BigDecimal minPrice, BigDecimal maxPrice, int page, int size,
                                        String sortBy, String sortDir) {
        QueryParts queryParts = buildSearchQuery(query, category, brand, gender, tag, minPrice, maxPrice, false, sortBy, sortDir);
        TypedQuery<Product> typedQuery = entityManager.createQuery(queryParts.query(), Product.class);
        applyParameters(typedQuery, queryParts.parameters());
        typedQuery.setFirstResult(page * size);
        typedQuery.setMaxResults(size);
        return typedQuery.getResultList();
    }

    public Long countSearchProducts(String query, String category, String brand, String gender, String tag,
                                    BigDecimal minPrice, BigDecimal maxPrice) {
        QueryParts queryParts = buildSearchQuery(query, category, brand, gender, tag, minPrice, maxPrice, true, "id", "desc");
        TypedQuery<Long> typedQuery = entityManager.createQuery(queryParts.query(), Long.class);
        applyParameters(typedQuery, queryParts.parameters());
        return typedQuery.getSingleResult();
    }

    public Product getProductById(Long id) {
        return entityManager.find(Product.class, id);
    }

    public Product getProductForUpdate(Long id) {
        return entityManager.find(Product.class, id, jakarta.persistence.LockModeType.PESSIMISTIC_WRITE);
    }

    public Product updateProduct(Product product) {
        Product mergedProduct = entityManager.merge(product);
        entityManager.flush();
        entityManager.refresh(mergedProduct);
        return mergedProduct;
    }

    public boolean reduceStock(Long productId, int quantity) {
        if (productId == null || quantity <= 0) {
            return false;
        }

        int updatedRows = entityManager.createQuery(
                        "UPDATE Product p SET p.stock = COALESCE(p.stock, 0) - :quantity " +
                                "WHERE p.id = :productId AND COALESCE(p.stock, 0) >= :quantity")
                .setParameter("productId", productId)
                .setParameter("quantity", quantity)
                .executeUpdate();

        return updatedRows > 0;
    }

    public boolean increaseStock(Long productId, int quantity) {
        if (productId == null || quantity <= 0) {
            return false;
        }

        int updatedRows = entityManager.createQuery(
                        "UPDATE Product p SET p.stock = COALESCE(p.stock, 0) + :quantity WHERE p.id = :productId")
                .setParameter("productId", productId)
                .setParameter("quantity", quantity)
                .executeUpdate();

        return updatedRows > 0;
    }

    public List<Product> getLowStockProducts() {
        TypedQuery<Product> query = entityManager.createQuery(
                "SELECT p FROM Product p WHERE COALESCE(p.stock, 0) < 10 ORDER BY p.stock ASC, p.id DESC",
                Product.class);
        query.setMaxResults(5);
        return query.getResultList();
    }

    public void deleteProduct(Long id) {
        Product product = entityManager.find(Product.class, id);
        if (product != null) {
            entityManager.remove(product);
        }
    }

    public Long countProducts() {
        return toLong(entityManager.createQuery("SELECT COUNT(p) FROM Product p").getSingleResult());
    }

    public Long countLowStockProducts() {
        return toLong(entityManager.createQuery(
                "SELECT COUNT(p) FROM Product p WHERE COALESCE(p.stock, 0) < 10"
        ).getSingleResult());
    }

    private Long toLong(Object value) {
        return value == null ? 0L : ((Number) value).longValue();
    }

    private QueryParts buildSearchQuery(String query, String category, String brand, String gender, String tag,
                                        BigDecimal minPrice, BigDecimal maxPrice, boolean countOnly,
                                        String sortBy, String sortDir) {
        StringBuilder jpql = new StringBuilder(countOnly ? "SELECT COUNT(p) FROM Product p WHERE 1=1" : "SELECT p FROM Product p WHERE 1=1");
        Map<String, Object> parameters = new HashMap<>();

        if (hasText(query)) {
            jpql.append(" AND (LOWER(COALESCE(p.name, '')) LIKE :query")
                .append(" OR LOWER(COALESCE(p.category, '')) LIKE :query")
                .append(" OR LOWER(COALESCE(p.brand, '')) LIKE :query")
                .append(" OR LOWER(COALESCE(p.gender, '')) LIKE :query")
                .append(" OR LOWER(COALESCE(p.tag, '')) LIKE :query)");
            parameters.put("query", likeValue(query));
        }
        if (hasText(category)) {
            jpql.append(" AND LOWER(COALESCE(p.category, '')) LIKE :category");
            parameters.put("category", likeValue(category));
        }
        if (hasText(brand)) {
            jpql.append(" AND LOWER(COALESCE(p.brand, '')) LIKE :brand");
            parameters.put("brand", likeValue(brand));
        }
        if (hasText(gender)) {
            jpql.append(" AND LOWER(COALESCE(p.gender, '')) LIKE :gender");
            parameters.put("gender", likeValue(gender));
        }
        if (hasText(tag)) {
            jpql.append(" AND LOWER(COALESCE(p.tag, '')) LIKE :tag");
            parameters.put("tag", likeValue(tag));
        }
        if (minPrice != null) {
            jpql.append(" AND p.price IS NOT NULL AND p.price >= :minPrice");
            parameters.put("minPrice", minPrice);
        }
        if (maxPrice != null) {
            jpql.append(" AND p.price IS NOT NULL AND p.price <= :maxPrice");
            parameters.put("maxPrice", maxPrice);
        }

        if (!countOnly) {
            jpql.append(" ORDER BY ").append(resolveSort(sortBy, sortDir));
        }

        return new QueryParts(jpql.toString(), parameters);
    }

    private void applyParameters(TypedQuery<?> query, Map<String, Object> parameters) {
        for (Map.Entry<String, Object> entry : parameters.entrySet()) {
            query.setParameter(entry.getKey(), entry.getValue());
        }
    }

    private String resolveSort(String sortBy, String sortDir) {
        String normalizedSortBy = sortBy == null ? "id" : sortBy.trim().toLowerCase();
        String field = switch (normalizedSortBy) {
            case "name" -> "p.name";
            case "category" -> "p.category";
            case "brand" -> "p.brand";
            case "gender" -> "p.gender";
            case "price" -> "p.price";
            case "stock" -> "p.stock";
            case "createdat" -> "p.createdAt";
            case "updatedat" -> "p.updatedAt";
            default -> "p.id";
        };

        String direction = "asc".equalsIgnoreCase(sortDir) ? "ASC" : "DESC";
        return field + " " + direction;
    }

    private boolean hasText(String value) {
        return value != null && !value.trim().isEmpty();
    }

    private String likeValue(String value) {
        return "%" + value.trim().toLowerCase() + "%";
    }

    private record QueryParts(String query, Map<String, Object> parameters) {}
}
