package com.styleora.dao;

import com.styleora.model.Role;
import jakarta.persistence.EntityManager;
import jakarta.persistence.PersistenceContext;
import jakarta.persistence.TypedQuery;
import jakarta.transaction.Transactional;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
@Transactional
public class RoleDao {

    @PersistenceContext
    private EntityManager entityManager;

    public Role saveRole(Role role) {
        role.setId(null);
        entityManager.persist(role);
        return role;
    }

    public List<Role> getAllRoles() {
        TypedQuery<Role> query = entityManager.createQuery(
                "SELECT r FROM Role r ORDER BY r.id DESC",
                Role.class
        );
        return query.getResultList();
    }

    public Role getRoleById(Long id) {
        return entityManager.find(Role.class, id);
    }

    public Role updateRole(Long id, Role role) {
        Role existingRole = entityManager.find(Role.class, id);
        if (existingRole == null) {
            return null;
        }

        existingRole.setName(role.getName());
        existingRole.setDescription(role.getDescription());
        existingRole.setStatus(role.getStatus());

        return entityManager.merge(existingRole);
    }

    public boolean deleteRole(Long id) {
        Role role = entityManager.find(Role.class, id);
        if (role != null) {
            entityManager.remove(role);
            return true;
        }
        return false;
    }
}
