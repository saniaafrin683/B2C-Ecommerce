package com.styleora.service;

import com.styleora.dao.RoleDao;
import com.styleora.model.Role;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
public class RoleService {

    @Autowired
    private RoleDao roleDao;

    public Role saveRole(Role role) {
        normalizeRole(role);
        return roleDao.saveRole(role);
    }

    public List<Role> getAllRoles() {
        return roleDao.getAllRoles();
    }

    public Role getRoleById(Long id) {
        return roleDao.getRoleById(id);
    }

    public Role updateRole(Long id, Role updatedRole) {
        Role existingRole = roleDao.getRoleById(id);
        if (existingRole == null) {
            return null;
        }

        existingRole.setName(updatedRole.getName());
        existingRole.setDescription(updatedRole.getDescription());
        existingRole.setStatus(updatedRole.getStatus());

        normalizeRole(existingRole);
        return roleDao.updateRole(id, existingRole);
    }

    public boolean deleteRole(Long id) {
        Role existingRole = roleDao.getRoleById(id);
        if (existingRole == null) {
            return false;
        }

        roleDao.deleteRole(id);
        return true;
    }

    private void normalizeRole(Role role) {
        if (role.getName() != null) {
            role.setName(role.getName().trim());
        }
        if (role.getDescription() != null) {
            role.setDescription(role.getDescription().trim());
        }
        if (role.getStatus() != null) {
            role.setStatus(role.getStatus().trim().toUpperCase());
        }
    }
}
