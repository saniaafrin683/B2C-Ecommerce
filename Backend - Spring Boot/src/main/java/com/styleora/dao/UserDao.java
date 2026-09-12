package com.styleora.dao;

import java.util.List;

import org.springframework.stereotype.Repository;

import com.styleora.model.User;

import jakarta.persistence.EntityManager;
import jakarta.persistence.PersistenceContext;
import jakarta.persistence.TypedQuery;
import jakarta.transaction.Transactional;

@Repository
@Transactional
public class UserDao {

    @PersistenceContext
    private EntityManager entityManager;

    public User saveUser(User user) {
        user.setId(null);
        entityManager.persist(user);
        return user;
    }

    public List<User> getAllUsers() {
        TypedQuery<User> query = entityManager.createQuery(
                "SELECT u FROM User u ORDER BY u.id DESC",
                User.class
        );
        return query.getResultList();
    }

    public User getUserById(Long id) {
        return entityManager.find(User.class, id);
    }

    public User updateUser(Long id, User user) {
        User existingUser = entityManager.find(User.class, id);
        if (existingUser == null) {
            return null;
        }

        existingUser.setUserCode(user.getUserCode());
        existingUser.setFirstName(user.getFirstName());
        existingUser.setLastName(user.getLastName());
        existingUser.setEmail(user.getEmail());
        existingUser.setPhone(user.getPhone());
        existingUser.setPassword(user.getPassword());
        existingUser.setRole(user.getRole());
        existingUser.setStatus(user.getStatus());
        existingUser.setAvatarUrl(user.getAvatarUrl());

        return entityManager.merge(existingUser);
    }

    public boolean deleteUser(Long id) {
        User user = entityManager.find(User.class, id);
        if (user != null) {
            entityManager.remove(user);
            return true;
        }
        return false;
    }
}
