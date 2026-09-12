package com.styleora.dao;

import com.styleora.model.AdminUser;
import jakarta.persistence.EntityManager;
import jakarta.persistence.NoResultException;
import jakarta.persistence.PersistenceContext;
import org.springframework.stereotype.Repository;

@Repository
public class AdminUserDao {

    @PersistenceContext
    private EntityManager entityManager;

    public AdminUser findByEmail(String email) {
        try {
            return entityManager.createQuery(
                    "SELECT a FROM AdminUser a WHERE lower(a.email) = lower(:email)",
                    AdminUser.class
            ).setParameter("email", email)
             .setMaxResults(1)
             .getSingleResult();
        } catch (NoResultException ex) {
            return null;
        }
    }

    public AdminUser save(AdminUser adminUser) {
        if (adminUser.getId() == null) {
            entityManager.persist(adminUser);
            return adminUser;
        }

        return entityManager.merge(adminUser);
    }
}
