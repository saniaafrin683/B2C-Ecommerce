package com.styleora.service;

import com.styleora.dao.AdminUserDao;
import com.styleora.model.AdminUser;
import jakarta.transaction.Transactional;
import org.springframework.boot.CommandLineRunner;
import org.springframework.core.annotation.Order;
import org.springframework.stereotype.Service;

@Service
@Order(5)
@Transactional
public class AdminUserSeedService implements CommandLineRunner {

    private static final String DEFAULT_ADMIN_EMAIL = "admin@styleora.com";
    private static final String DEFAULT_MODERATOR_EMAIL = "moderator@styleora.com";
    private static final String DEFAULT_SALES_EMAIL = "sales@styleora.com";
    private static final String DEFAULT_ADMIN_PASSWORD = "123456";

    private final AdminUserDao adminUserDao;
    private final AdminAuthService adminAuthService;

    public AdminUserSeedService(AdminUserDao adminUserDao, AdminAuthService adminAuthService) {
        this.adminUserDao = adminUserDao;
        this.adminAuthService = adminAuthService;
    }

    @Override
    public void run(String... args) {
        seedAdminUser(DEFAULT_ADMIN_EMAIL, DEFAULT_ADMIN_PASSWORD, "ADMIN", true);
        seedAdminUser(DEFAULT_MODERATOR_EMAIL, DEFAULT_ADMIN_PASSWORD, "MODERATOR", false);
        seedAdminUser(DEFAULT_SALES_EMAIL, DEFAULT_ADMIN_PASSWORD, "SALES", false);
    }

    private void seedAdminUser(String email, String password, String role, boolean resetExistingPassword) {
        AdminUser existingUser = adminUserDao.findByEmail(email);
        if (existingUser != null) {
            adminAuthService.ensureRole(existingUser, role);
            if (resetExistingPassword) {
                adminAuthService.resetPassword(existingUser, password);
            } else {
                adminAuthService.ensurePasswordHash(existingUser, password);
            }
            return;
        }

        AdminUser adminUser = new AdminUser(email, password, role);
        adminUserDao.save(adminUser);
        adminAuthService.ensureRole(adminUser, role);
        adminAuthService.resetPassword(adminUser, password);
    }
}
