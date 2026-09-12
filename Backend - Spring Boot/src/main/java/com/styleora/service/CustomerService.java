package com.styleora.service;

import com.styleora.dao.CustomerDao;
import com.styleora.dto.CustomerAuthResponse;
import com.styleora.dto.CustomerLoginRequest;
import com.styleora.dto.CustomerProfileResponse;
import com.styleora.dto.CustomerRegisterRequest;
import com.styleora.model.Customer;
import com.styleora.security.JwtService;
import com.styleora.util.CustomerStatusValidator;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.HttpStatus;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.util.StringUtils;
import org.springframework.web.server.ResponseStatusException;

import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;
import java.util.Locale;

@Service
public class CustomerService {
    private static final Logger LOGGER = LoggerFactory.getLogger(CustomerService.class);

    private final CustomerDao customerDao;
    private final PasswordEncoder passwordEncoder;
    private final JwtService jwtService;

    public CustomerService(CustomerDao customerDao, PasswordEncoder passwordEncoder, JwtService jwtService) {
        this.customerDao = customerDao;
        this.passwordEncoder = passwordEncoder;
        this.jwtService = jwtService;
    }

    public CustomerAuthResponse register(CustomerRegisterRequest request) {
        String normalizedEmail = normalizeEmail(request.getEmail());
        if (!StringUtils.hasText(normalizedEmail)) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Email is required.");
        }
        if (!StringUtils.hasText(request.getPassword())) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Password is required.");
        }
        LOGGER.info("Customer registration attempt email={}", normalizedEmail);

        if (customerDao.findCustomerByEmail(normalizedEmail) != null) {
            LOGGER.warn("Customer registration blocked duplicate email={}", normalizedEmail);
            throw new ResponseStatusException(HttpStatus.CONFLICT, "An account with this email already exists.");
        }

        Customer customer = new Customer();
        customer.setCustomerCode("CUS-" + System.currentTimeMillis());
        customer.setFullName(request.getFullName().trim());
        customer.setEmail(normalizedEmail);
        customer.setPassword(passwordEncoder.encode(request.getPassword()));
        customer.setPhone(normalizePhone(request.getPhone()));
        customer.setAddress(safeTrim(request.getAddress()));
        customer.setCity(safeTrim(request.getCity()));
        customer.setCountry(safeTrim(request.getCountry()));
        customer.setStatus(CustomerStatusValidator.STATUS_ACTIVE);
        customer.setRegisteredAt(LocalDate.now());
        customer.setTotalOrders(0);
        customer.setTotalSpend(0.0);
        applyCustomerDefaults(customer, true);

        Customer savedCustomer = customerDao.saveCustomer(customer);
        LOGGER.info("Customer registration successful id={}, email={}, status={}", savedCustomer.getId(), savedCustomer.getEmail(), savedCustomer.getStatus());
        return buildAuthResponse(savedCustomer, "Registration successful.");
    }

    public CustomerAuthResponse login(CustomerLoginRequest request) {
        String normalizedEmail = normalizeEmail(request.getEmail());
        if (!StringUtils.hasText(normalizedEmail) || !StringUtils.hasText(request.getPassword())) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Email and password are required.");
        }
        LOGGER.info("Customer login attempt email={}", normalizedEmail);
        Customer customer = customerDao.findCustomerByEmail(normalizedEmail);

        if (customer == null || !StringUtils.hasText(customer.getPassword()) || !passwordEncoder.matches(request.getPassword(), customer.getPassword())) {
            LOGGER.warn("Customer login rejected invalid credentials email={}", normalizedEmail);
            throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Invalid email or password.");
        }

        if (CustomerStatusValidator.STATUS_INACTIVE.equalsIgnoreCase(customer.getStatus())
                || CustomerStatusValidator.STATUS_SUSPENDED.equalsIgnoreCase(customer.getStatus())
                || CustomerStatusValidator.STATUS_DELETED.equalsIgnoreCase(customer.getStatus())) {
            LOGGER.warn("Customer login rejected inactive account id={}, email={}, status={}", customer.getId(), customer.getEmail(), customer.getStatus());
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "This account is inactive.");
        }

        LOGGER.info("Customer login successful id={}, email={}, status={}", customer.getId(), customer.getEmail(), customer.getStatus());
        return buildAuthResponse(customer, "Login successful.");
    }

    public CustomerProfileResponse getProfile(String email) {
        Customer customer = customerDao.findCustomerByEmail(email);
        if (customer == null) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "Customer not found.");
        }

        return toProfileResponse(customer);
    }

    public Customer createCustomer(Customer customer) {
        if (customer == null) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Customer payload is required.");
        }

        customer.setId(null);
        applyCustomerDefaults(customer, false);
        validateUniqueEmail(customer.getEmail(), null);

        if (!StringUtils.hasText(customer.getPassword())) {
            customer.setPassword(passwordEncoder.encode("styleora123"));
        } else {
            customer.setPassword(passwordEncoder.encode(customer.getPassword().trim()));
        }

        return customerDao.saveCustomer(customer);
    }

    public List<Customer> getAllCustomers() {
        List<Customer> customers = customerDao.getAllCustomers();
        LOGGER.info("Customer list loaded count={}", customers.size());
        return customers;
    }

    public List<Customer> getDeletedCustomers() {
        return customerDao.getDeletedCustomers();
    }

    public Customer getCustomerById(Long id) {
        return customerDao.getCustomerById(id);
    }

    public Customer updateCustomer(Long id, Customer customer) {
        Customer existingCustomer = customerDao.getCustomerById(id);
        if (existingCustomer == null) {
            return null;
        }

        String nextEmail = normalizeEmail(customer != null ? customer.getEmail() : existingCustomer.getEmail());
        validateUniqueEmail(nextEmail, id);

        Customer normalizedCustomer = new Customer();
        normalizedCustomer.setId(id);
        normalizedCustomer.setCustomerCode(StringUtils.hasText(customer != null ? customer.getCustomerCode() : null)
                ? customer.getCustomerCode().trim()
                : existingCustomer.getCustomerCode());
        normalizedCustomer.setFullName(StringUtils.hasText(customer != null ? customer.getFullName() : null)
                ? customer.getFullName().trim()
                : existingCustomer.getFullName());
        normalizedCustomer.setEmail(nextEmail);
        normalizedCustomer.setPassword(existingCustomer.getPassword());
        normalizedCustomer.setPhone(normalizePhone(customer != null ? customer.getPhone() : existingCustomer.getPhone()));
        normalizedCustomer.setGender(normalizeGender(customer != null ? customer.getGender() : existingCustomer.getGender()));
        normalizedCustomer.setDateOfBirth(customer != null && customer.getDateOfBirth() != null
                ? customer.getDateOfBirth()
                : existingCustomer.getDateOfBirth());
        normalizedCustomer.setAddress(safeTrim(customer != null ? customer.getAddress() : existingCustomer.getAddress()));
        normalizedCustomer.setCity(safeTrim(customer != null ? customer.getCity() : existingCustomer.getCity()));
        normalizedCustomer.setCountry(safeTrim(customer != null ? customer.getCountry() : existingCustomer.getCountry()));
        normalizedCustomer.setTotalOrders(customer != null && customer.getTotalOrders() != null
                ? Math.max(0, customer.getTotalOrders())
                : existingCustomer.getTotalOrders());
        normalizedCustomer.setTotalSpend(customer != null && customer.getTotalSpend() != null
                ? Math.max(0D, customer.getTotalSpend())
                : existingCustomer.getTotalSpend());
        normalizedCustomer.setStatus(normalizeStatus(customer != null ? customer.getStatus() : existingCustomer.getStatus(), false));
        normalizedCustomer.setRegisteredAt(customer != null && customer.getRegisteredAt() != null
                ? customer.getRegisteredAt()
                : existingCustomer.getRegisteredAt());
        normalizedCustomer.setNotes(safeTrim(customer != null ? customer.getNotes() : existingCustomer.getNotes()));
        applyCustomerDefaults(normalizedCustomer, false);

        return customerDao.updateCustomer(id, normalizedCustomer);
    }

    public boolean deleteCustomer(Long id) {
        return customerDao.deleteCustomer(id);
    }

    public boolean restoreCustomer(Long id) {
        return customerDao.restoreCustomer(id);
    }

    public boolean permanentlyDeleteCustomer(Long id) {
        return customerDao.permanentlyDeleteCustomer(id);
    }

    public List<Customer> deleteCustomersByName(String name) {
        String normalizedName = safeTrim(name);
        if (!StringUtils.hasText(normalizedName)) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Customer name is required.");
        }

        List<Customer> matchedCustomers = customerDao.findCustomersByName(normalizedName);
        LOGGER.info("Customer delete-by-name lookup name='{}' matched={}", normalizedName, matchedCustomers.size());

        List<Customer> affectedCustomers = new ArrayList<>();
        for (Customer customer : matchedCustomers) {
            if (customer == null || customer.getId() == null) {
                continue;
            }

            long linkedOrders = customerDao.countLinkedOrders(customer.getId(), customer.getEmail());
            long linkedShipments = customerDao.countLinkedShipments(customer.getId(), customer.getEmail());
            long linkedReturns = customerDao.countLinkedReturnRequests(customer.getId());

            if (linkedOrders > 0 || linkedShipments > 0 || linkedReturns > 0) {
                customerDao.markCustomerDeleted(customer);
                LOGGER.info(
                        "Customer soft deleted id={}, name='{}', orders={}, shipments={}, returns={}",
                        customer.getId(),
                        customer.getFullName(),
                        linkedOrders,
                        linkedShipments,
                        linkedReturns
                );
                affectedCustomers.add(customer);
                continue;
            }

            String fullName = customer.getFullName();
            Long customerId = customer.getId();
            customerDao.permanentlyDeleteCustomer(customerId);
            LOGGER.info("Customer hard deleted id={}, name='{}'", customerId, fullName);

            Customer deletedMarker = new Customer();
            deletedMarker.setId(customerId);
            deletedMarker.setFullName(fullName);
            deletedMarker.setEmail(customer.getEmail());
            deletedMarker.setStatus(CustomerStatusValidator.STATUS_DELETED);
            affectedCustomers.add(deletedMarker);
        }

        return affectedCustomers;
    }

    private CustomerAuthResponse buildAuthResponse(Customer customer, String message) {
        String token = jwtService.generateToken(customer.getId(), customer.getEmail(), "CUSTOMER");
        return new CustomerAuthResponse(true, message, token, "CUSTOMER", toProfileResponse(customer));
    }

    private CustomerProfileResponse toProfileResponse(Customer customer) {
        return new CustomerProfileResponse(
                customer.getId(),
                customer.getCustomerCode(),
                customer.getFullName(),
                customer.getEmail(),
                customer.getPhone(),
                customer.getAddress(),
                customer.getCity(),
                customer.getCountry(),
                customer.getStatus(),
                customer.getRegisteredAt()
        );
    }

    private void applyCustomerDefaults(Customer customer, boolean forceActiveStatus) {
        if (customer == null) {
            return;
        }

        customer.setCustomerCode(StringUtils.hasText(customer.getCustomerCode())
                ? customer.getCustomerCode().trim()
                : "CUS-" + System.currentTimeMillis());
        customer.setFullName(safeTrim(customer.getFullName()));
        customer.setEmail(normalizeEmail(customer.getEmail()));
        customer.setPhone(normalizePhone(customer.getPhone()));
        customer.setGender(normalizeGender(customer.getGender()));
        customer.setAddress(safeTrim(customer.getAddress()));
        customer.setCity(safeTrim(customer.getCity()));
        customer.setCountry(safeTrim(customer.getCountry()));
        customer.setNotes(safeTrim(customer.getNotes()));
        customer.setRegisteredAt(customer.getRegisteredAt() == null ? LocalDate.now() : customer.getRegisteredAt());
        customer.setTotalOrders(customer.getTotalOrders() == null ? 0 : Math.max(0, customer.getTotalOrders()));
        customer.setTotalSpend(customer.getTotalSpend() == null ? 0D : Math.max(0D, customer.getTotalSpend()));
        customer.setStatus(forceActiveStatus
                ? CustomerStatusValidator.STATUS_ACTIVE
                : normalizeStatus(customer.getStatus(), true));
    }

    private void validateUniqueEmail(String email, Long currentCustomerId) {
        if (!StringUtils.hasText(email)) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Email is required.");
        }

        Customer existingCustomer = customerDao.findCustomerByEmail(email);
        if (existingCustomer != null && (currentCustomerId == null || !existingCustomer.getId().equals(currentCustomerId))) {
            throw new ResponseStatusException(HttpStatus.CONFLICT, "An account with this email already exists.");
        }
    }

    private String normalizeEmail(String email) {
        String normalizedEmail = safeTrim(email);
        return normalizedEmail == null ? null : normalizedEmail.toLowerCase(Locale.ROOT);
    }

    private String normalizePhone(String phone) {
        String normalizedPhone = safeTrim(phone);
        return StringUtils.hasText(normalizedPhone) ? normalizedPhone : null;
    }

    private String normalizeGender(String gender) {
        String normalizedGender = safeTrim(gender);
        return StringUtils.hasText(normalizedGender) ? normalizedGender.toUpperCase(Locale.ROOT) : null;
    }

    private String normalizeStatus(String status, boolean allowDeleted) {
        String normalizedStatus = safeTrim(status);
        if (!StringUtils.hasText(normalizedStatus)) {
            return CustomerStatusValidator.STATUS_ACTIVE;
        }

        String upperStatus = normalizedStatus.toUpperCase(Locale.ROOT);
        if (CustomerStatusValidator.STATUS_ACTIVE.equals(upperStatus) || "ACTIVE CUSTOMER".equals(upperStatus) || "ACTIVATED".equals(upperStatus)) {
            return CustomerStatusValidator.STATUS_ACTIVE;
        }
        if (CustomerStatusValidator.STATUS_INACTIVE.equals(upperStatus) || "BLOCKED".equals(upperStatus)) {
            return CustomerStatusValidator.STATUS_INACTIVE;
        }
        if (CustomerStatusValidator.STATUS_SUSPENDED.equals(upperStatus)) {
            return CustomerStatusValidator.STATUS_SUSPENDED;
        }
        if (CustomerStatusValidator.STATUS_DELETED.equals(upperStatus)) {
            return allowDeleted ? CustomerStatusValidator.STATUS_DELETED : CustomerStatusValidator.STATUS_INACTIVE;
        }
        return CustomerStatusValidator.normalize(status, "CustomerService");
    }

    private String safeTrim(String value) {
        return value == null ? null : value.trim();
    }
}
