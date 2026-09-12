package com.styleora.service;

import com.styleora.dao.CustomerDao;
import com.styleora.model.Customer;
import com.styleora.util.CustomerStatusValidator;
import jakarta.transaction.Transactional;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.CommandLineRunner;
import org.springframework.core.annotation.Order;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

import java.time.LocalDate;

@Service
@Order(15)
@Transactional
public class CustomerAuthSeedService implements CommandLineRunner {
    private static final Logger LOGGER = LoggerFactory.getLogger(CustomerAuthSeedService.class);

    private static final String DEFAULT_CUSTOMER_EMAIL = "customer@styleora.com";
    private static final String DEFAULT_CUSTOMER_PASSWORD = "123456";
    private final CustomerDao customerDao;
    private final PasswordEncoder passwordEncoder;

    public CustomerAuthSeedService(CustomerDao customerDao, PasswordEncoder passwordEncoder) {
        this.customerDao = customerDao;
        this.passwordEncoder = passwordEncoder;
    }

    @Override
    public void run(String... args) {
        try {
            Customer existingCustomer = customerDao.findCustomerByEmail(DEFAULT_CUSTOMER_EMAIL);
            if (existingCustomer != null) {
                safelySaveExistingCustomer(existingCustomer);
                return;
            }

            safelyInsertSeedCustomer();
        } catch (Exception ex) {
            LOGGER.error("Customer seed skipped due to invalid seed data", ex);
        }
    }

    private void safelySaveExistingCustomer(Customer customer) {
        try {
            normalizeSeedCustomer(customer);
            customerDao.save(customer);
        } catch (Exception ex) {
            LOGGER.error("Customer seed update skipped for email={}", DEFAULT_CUSTOMER_EMAIL, ex);
        }
    }

    private void safelyInsertSeedCustomer() {
        try {
            Customer customer = new Customer();
            customer.setCustomerCode("CUS-STYLEORA-001");
            customer.setFullName("Styleora Customer");
            customer.setEmail(DEFAULT_CUSTOMER_EMAIL);
            customer.setPassword(passwordEncoder.encode(DEFAULT_CUSTOMER_PASSWORD));
            customer.setPhone("01700000000");
            customer.setAddress("Styleora Demo Address");
            customer.setCity("Dhaka");
            customer.setCountry("Bangladesh");
            customer.setStatus(CustomerStatusValidator.STATUS_ACTIVE);
            customer.setTotalOrders(0);
            customer.setTotalSpend(0.0);
            customer.setRegisteredAt(LocalDate.now());
            customer.setNotes("Stable seeded customer for login verification");
            normalizeSeedCustomer(customer);
            customerDao.saveCustomer(customer);
        } catch (Exception ex) {
            LOGGER.error("Customer seed insert skipped for email={}", DEFAULT_CUSTOMER_EMAIL, ex);
        }
    }

    private void normalizeSeedCustomer(Customer customer) {
        customer.setEmail(DEFAULT_CUSTOMER_EMAIL);
        customer.setStatus(CustomerStatusValidator.normalize(customer.getStatus(), "CustomerAuthSeedService"));
        customer.setPassword(resolvePassword(customer.getPassword()));

        if (customer.getCustomerCode() == null || customer.getCustomerCode().trim().isEmpty()) {
            customer.setCustomerCode("CUS-STYLEORA-001");
        }
        if (customer.getFullName() == null || customer.getFullName().trim().isEmpty()) {
            customer.setFullName("Styleora Customer");
        }
        if (customer.getCountry() == null || customer.getCountry().trim().isEmpty()) {
            customer.setCountry("Bangladesh");
        }
        if (customer.getCity() == null || customer.getCity().trim().isEmpty()) {
            customer.setCity("Dhaka");
        }
        if (customer.getRegisteredAt() == null) {
            customer.setRegisteredAt(LocalDate.now());
        }
        if (customer.getTotalOrders() == null) {
            customer.setTotalOrders(0);
        }
        if (customer.getTotalSpend() == null) {
            customer.setTotalSpend(0.0);
        }
    }

    private String resolvePassword(String existingPassword) {
        if (existingPassword != null
                && (existingPassword.startsWith("$2a$") || existingPassword.startsWith("$2b$") || existingPassword.startsWith("$2y$"))) {
            return existingPassword;
        }

        String candidatePassword = existingPassword == null || existingPassword.trim().isEmpty()
                ? DEFAULT_CUSTOMER_PASSWORD
                : existingPassword;
        return passwordEncoder.encode(candidatePassword);
    }
}
