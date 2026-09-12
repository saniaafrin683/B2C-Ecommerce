package com.styleora.dao;

import java.util.List;

import org.springframework.stereotype.Repository;

import com.styleora.model.Category;

import jakarta.persistence.EntityManager;
import jakarta.persistence.PersistenceContext;
import jakarta.persistence.TypedQuery;
import jakarta.transaction.Transactional;

@Repository
@Transactional
public class CategoryDao {

    @PersistenceContext
    private EntityManager entityManager;

    public Category saveCategory(Category category) {
        category.setId(null);
        entityManager.persist(category);
        return category;
    }

    public List<Category> getAllCategories() {

        TypedQuery<Category> query = entityManager.createQuery(
                "SELECT c FROM Category c ORDER BY c.id DESC",
                Category.class
        );

        return query.getResultList();
    }

    public long countAll() {
        Long count = entityManager.createQuery(
                "SELECT COUNT(c) FROM Category c",
                Long.class
        ).getSingleResult();

        return count == null ? 0L : count;
    }

    public Category getCategoryById(Long id) {
        return entityManager.find(Category.class, id);
    }

    public boolean existsByCategoryTitle(String categoryTitle) {
        Long count = entityManager.createQuery(
                "SELECT COUNT(c) FROM Category c WHERE LOWER(c.categoryTitle) = LOWER(:categoryTitle)",
                Long.class
        )
        .setParameter("categoryTitle", categoryTitle)
        .getSingleResult();

        return count != null && count > 0;
    }

    public Category findByCategoryTitle(String categoryTitle) {
        List<Category> results = entityManager.createQuery(
                "SELECT c FROM Category c WHERE LOWER(c.categoryTitle) = LOWER(:categoryTitle)",
                Category.class
        )
        .setParameter("categoryTitle", categoryTitle)
        .setMaxResults(1)
        .getResultList();

        return results.isEmpty() ? null : results.get(0);
    }

    public Category updateCategory(Category category) {
        if (category == null || category.getId() == null) {
            return null;
        }
        return entityManager.merge(category);
    }

    public void deleteCategory(Long id) {

        Category category = entityManager.find(Category.class, id);

        if (category != null) {
            entityManager.remove(category);
        }
    }
}
