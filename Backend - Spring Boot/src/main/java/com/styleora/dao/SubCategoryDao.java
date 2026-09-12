package com.styleora.dao;

import com.styleora.model.SubCategory;
import jakarta.persistence.EntityManager;
import jakarta.persistence.PersistenceContext;
import jakarta.persistence.TypedQuery;
import jakarta.transaction.Transactional;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
@Transactional
public class SubCategoryDao {

    @PersistenceContext
    private EntityManager entityManager;

    public SubCategory saveSubCategory(SubCategory subCategory) {
        subCategory.setId(null);
        entityManager.persist(subCategory);
        return subCategory;
    }

    public List<SubCategory> getAllSubCategories() {
        TypedQuery<SubCategory> query = entityManager.createQuery(
                "SELECT sc FROM SubCategory sc ORDER BY sc.categoryName ASC, sc.subCategoryName ASC, sc.id DESC",
                SubCategory.class
        );
        return query.getResultList();
    }

    public long countAll() {
        Long count = entityManager.createQuery(
                "SELECT COUNT(sc) FROM SubCategory sc",
                Long.class
        ).getSingleResult();

        return count == null ? 0L : count;
    }

    public long countByCategoryId(Long categoryId) {
        Long count = entityManager.createQuery(
                "SELECT COUNT(sc) FROM SubCategory sc WHERE sc.categoryId = :categoryId",
                Long.class
        ).setParameter("categoryId", categoryId).getSingleResult();

        return count == null ? 0L : count;
    }

    public SubCategory getSubCategoryById(Long id) {
        return entityManager.find(SubCategory.class, id);
    }

    public List<SubCategory> getSubCategoriesByCategoryId(Long categoryId) {
        TypedQuery<SubCategory> query = entityManager.createQuery(
                "SELECT sc FROM SubCategory sc WHERE sc.categoryId = :categoryId ORDER BY sc.subCategoryName ASC, sc.id DESC",
                SubCategory.class
        );
        query.setParameter("categoryId", categoryId);
        return query.getResultList();
    }

    public boolean existsByNameAndCategoryId(String subCategoryName, Long categoryId) {
        Long count = entityManager.createQuery(
                "SELECT COUNT(sc) FROM SubCategory sc WHERE LOWER(sc.subCategoryName) = LOWER(:subCategoryName) AND sc.categoryId = :categoryId",
                Long.class
        )
        .setParameter("subCategoryName", subCategoryName)
        .setParameter("categoryId", categoryId)
        .getSingleResult();

        return count != null && count > 0;
    }

    public SubCategory updateSubCategory(Long id, SubCategory updatedSubCategory) {
        SubCategory managedSubCategory = entityManager.find(SubCategory.class, id);

        if (managedSubCategory == null) {
            return null;
        }

        managedSubCategory.setSubCategoryCode(updatedSubCategory.getSubCategoryCode());
        managedSubCategory.setSubCategoryName(updatedSubCategory.getSubCategoryName());
        managedSubCategory.setCategoryId(updatedSubCategory.getCategoryId());
        managedSubCategory.setCategoryName(updatedSubCategory.getCategoryName());
        managedSubCategory.setCreatedBy(updatedSubCategory.getCreatedBy());
        managedSubCategory.setStock(updatedSubCategory.getStock());
        managedSubCategory.setTagId(updatedSubCategory.getTagId());
        managedSubCategory.setDescription(updatedSubCategory.getDescription());
        managedSubCategory.setImageUrl(updatedSubCategory.getImageUrl());
        managedSubCategory.setStatus(updatedSubCategory.getStatus());

        entityManager.flush();
        return managedSubCategory;
    }

    public void deleteSubCategory(Long id) {
        SubCategory subCategory = entityManager.find(SubCategory.class, id);

        if (subCategory != null) {
            entityManager.remove(subCategory);
        }
    }
}
