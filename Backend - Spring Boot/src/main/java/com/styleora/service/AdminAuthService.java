package com.styleora.service;

import com.styleora.dao.AdminUserDao;
import com.styleora.dto.AdminLoginRequest;
import com.styleora.dto.AdminLoginResponse;
import com.styleora.model.AdminUser;
import com.styleora.security.JwtService;
import org.springframework.stereotype.Service;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.web.server.ResponseStatusException;
import org.springframework.http.HttpStatus;

@Service
public class AdminAuthService {

    private final AdminUserDao adminUserDao;
    private final PasswordEncoder passwordEncoder;
    private final JwtService jwtService;

    public AdminAuthService(AdminUserDao adminUserDao, PasswordEncoder passwordEncoder, JwtService jwtService) {
        this.adminUserDao = adminUserDao;
        this.passwordEncoder = passwordEncoder;
        this.jwtService = jwtService;
    }

    public AdminLoginResponse login(AdminLoginRequest request) {
        AdminUser adminUser = adminUserDao.findByEmail(request.getEmail().trim());
        if (adminUser == null || !passwordEncoder.matches(request.getPassword(), adminUser.getPassword())) {
            return new AdminLoginResponse(false, "Invalid email or password.", null, null, null, null);
        }

        String role = resolveAdminRole(adminUser);
        String token = jwtService.generateToken(adminUser.getId(), adminUser.getEmail(), role);
        return new AdminLoginResponse(true, "Login successful.", adminUser.getEmail(), adminUser.getEmail(), token, role);
    }

    public void ensurePasswordHash(AdminUser adminUser, String fallbackPlainPassword) {
        if (adminUser == null || adminUser.getPassword() == null) {
            return;
        }

        if (adminUser.getPassword().startsWith("$2a$") || adminUser.getPassword().startsWith("$2b$") || adminUser.getPassword().startsWith("$2y$")) {
            return;
        }

        String candidatePassword = adminUser.getPassword().trim().isEmpty() ? fallbackPlainPassword : adminUser.getPassword();
        if (candidatePassword == null || candidatePassword.trim().isEmpty()) {
            throw new ResponseStatusException(HttpStatus.INTERNAL_SERVER_ERROR, "Admin password is not configured.");
        }

        adminUser.setPassword(passwordEncoder.encode(candidatePassword));
        adminUserDao.save(adminUser);
    }

    public void resetPassword(AdminUser adminUser, String rawPassword) {
        if (adminUser == null) {
            return;
        }

        if (rawPassword == null || rawPassword.trim().isEmpty()) {
            throw new ResponseStatusException(HttpStatus.INTERNAL_SERVER_ERROR, "Admin password is not configured.");
        }

        adminUser.setPassword(passwordEncoder.encode(rawPassword));
        adminUserDao.save(adminUser);
    }

    public String ensureRole(AdminUser adminUser, String fallbackRole) {
        if (adminUser == null) {
            return normalizeRole(fallbackRole);
        }

        String normalizedRole = normalizeRole(adminUser.getRole());
        if (normalizedRole == null) {
            normalizedRole = normalizeRole(fallbackRole);
        }

        if (normalizedRole == null) {
            normalizedRole = "ADMIN";
        }

        if (!normalizedRole.equals(adminUser.getRole())) {
            adminUser.setRole(normalizedRole);
            adminUserDao.save(adminUser);
        }

        return normalizedRole;
    }

    private String resolveAdminRole(AdminUser adminUser) {
        return ensureRole(adminUser, "ADMIN");
    }

    private String normalizeRole(String role) {
        if (role == null || role.trim().isEmpty()) {
            return null;
        }

        return role.trim().toUpperCase();
    }
}
