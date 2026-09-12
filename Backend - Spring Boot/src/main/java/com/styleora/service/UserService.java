package com.styleora.service;

import java.util.List;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import com.styleora.dao.UserDao;
import com.styleora.model.User;

@Service
public class UserService {

    @Autowired
    private UserDao userDao;

    public User saveUser(User user) {
        return userDao.saveUser(user);
    }

    public List<User> getAllUsers() {
        return userDao.getAllUsers();
    }

    public User getUserById(Long id) {
        return userDao.getUserById(id);
    }

    public User updateUser(Long id, User updatedUser) {
        User existingUser = userDao.getUserById(id);
        if (existingUser == null) {
            return null;
        }

        existingUser.setUserCode(updatedUser.getUserCode());
        existingUser.setFirstName(updatedUser.getFirstName());
        existingUser.setLastName(updatedUser.getLastName());
        existingUser.setEmail(updatedUser.getEmail());
        existingUser.setPhone(updatedUser.getPhone());
        existingUser.setRole(updatedUser.getRole());
        existingUser.setStatus(updatedUser.getStatus());
        existingUser.setAvatarUrl(updatedUser.getAvatarUrl());

        if (updatedUser.getPassword() != null && !updatedUser.getPassword().trim().isEmpty()) {
            existingUser.setPassword(updatedUser.getPassword());
        }

        return userDao.updateUser(id, existingUser);
    }

    public boolean deleteUser(Long id) {
        User existingUser = userDao.getUserById(id);
        if (existingUser == null) {
            return false;
        }

        userDao.deleteUser(id);
        return true;
    }
}
