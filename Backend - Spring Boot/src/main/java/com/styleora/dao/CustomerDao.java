package com.styleora.dao;

import com.styleora.model.Customer;
import jakarta.persistence.EntityManager;
import jakarta.persistence.NoResultException;
import jakarta.persistence.PersistenceException;
import jakarta.persistence.PersistenceContext;
import jakarta.transaction.Transactional;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Repository;

import java.time.LocalDate;
import java.util.List;

@Repository
@Transactional
public class CustomerDao {
    private static final Logger LOGGER = LoggerFactory.getLogger(CustomerDao.class);
    private static final String SAMPLE_CUSTOMER_EMAIL_SUFFIX = "%@styleora.test";

    @PersistenceContext
    private EntityManager entityManager;

    public Customer saveCustomer(Customer customer) {
        entityManager.persist(customer);
        entityManager.flush();
        return customer;
    }

    public List<Customer> getAllCustomers() {
        List<Customer> customers = entityManager
                .createQuery("from Customer c order by c.id desc", Customer.class)
                .getResultList();
        LOGGER.info("CustomerDao.getAllCustomers returned count={}", customers.size());
        return customers;
    }

    public List<Customer> getDeletedCustomers() {
        return entityManager
                .createQuery("from Customer c where upper(coalesce(c.status, '')) = 'DELETED' order by c.id desc", Customer.class)
                .getResultList();
    }

    public Customer getCustomerById(Long id) {
        return entityManager.find(Customer.class, id);
    }

    public List<Customer> findCustomersByName(String name) {
        String normalizedName = name == null ? "" : name.trim().toLowerCase();
        return entityManager.createQuery(
                "select c from Customer c " +
                        "where lower(coalesce(c.fullName, '')) = :exactName " +
                        "or lower(coalesce(c.fullName, '')) like :partialName " +
                        "order by c.id desc",
                Customer.class
        ).setParameter("exactName", normalizedName)
         .setParameter("partialName", "%" + normalizedName + "%")
         .getResultList();
    }

    public Customer findByEmail(String email) {
        try {
            return entityManager.createQuery(
                    "select c from Customer c where lower(c.email) = lower(:email) and upper(coalesce(c.status, 'ACTIVE')) = 'ACTIVE'",
                    Customer.class
            ).setParameter("email", email)
             .setMaxResults(1)
             .getSingleResult();
        } catch (NoResultException ex) {
            return null;
        }
    }

    public Customer findCustomerByEmail(String email) {
        try {
            return entityManager.createQuery(
                    "select c from Customer c where lower(c.email) = lower(:email)",
                    Customer.class
            ).setParameter("email", email)
             .setMaxResults(1)
             .getSingleResult();
        } catch (NoResultException ex) {
            return null;
        }
    }

    public Customer updateCustomer(Long id, Customer customer) {
        Customer existingCustomer = entityManager.find(Customer.class, id);

        if (existingCustomer == null) {
            return null;
        }

        existingCustomer.setCustomerCode(customer.getCustomerCode());
        existingCustomer.setFullName(customer.getFullName());
        existingCustomer.setEmail(customer.getEmail());
        existingCustomer.setPhone(customer.getPhone());
        existingCustomer.setGender(customer.getGender());
        existingCustomer.setDateOfBirth(customer.getDateOfBirth());
        existingCustomer.setAddress(customer.getAddress());
        existingCustomer.setCity(customer.getCity());
        existingCustomer.setCountry(customer.getCountry());
        existingCustomer.setTotalOrders(customer.getTotalOrders());
        existingCustomer.setTotalSpend(customer.getTotalSpend());
        existingCustomer.setStatus(customer.getStatus());
        existingCustomer.setRegisteredAt(customer.getRegisteredAt());
        existingCustomer.setNotes(customer.getNotes());

        return existingCustomer;
    }

    public Customer save(Customer customer) {
        return entityManager.merge(customer);
    }

    public boolean deleteCustomer(Long id) {
        Customer customer = entityManager.find(Customer.class, id);
        if (customer == null) {
            return false;
        }

        customer.setStatus("DELETED");
        entityManager.flush();
        return true;
    }

    public boolean restoreCustomer(Long id) {
        Customer customer = entityManager.find(Customer.class, id);
        if (customer == null) {
            return false;
        }

        customer.setStatus("ACTIVE");
        entityManager.flush();
        return true;
    }

    public long countLinkedOrders(Long customerId, String customerEmail) {
        return toLong(entityManager.createQuery(
                "select count(o) from Order o where " +
                        "(o.customer is not null and o.customer.id = :customerId) " +
                        "or (:customerEmail is not null and lower(coalesce(o.customerEmail, '')) = lower(:customerEmail))"
        ).setParameter("customerId", customerId)
         .setParameter("customerEmail", customerEmail)
         .getSingleResult());
    }

    public long countLinkedReturnRequests(Long customerId) {
        return toLong(entityManager.createQuery(
                "select count(rr) from ReturnRequest rr where rr.customerId = :customerId"
        ).setParameter("customerId", customerId).getSingleResult());
    }

    public long countLinkedShipments(Long customerId, String customerEmail) {
        return toLong(entityManager.createQuery(
                "select count(s) from Shipment s where exists (" +
                        "select 1 from Order o where o.id = s.orderId and (" +
                        "(o.customer is not null and o.customer.id = :customerId) " +
                        "or (:customerEmail is not null and lower(coalesce(o.customerEmail, '')) = lower(:customerEmail))" +
                        "))"
        ).setParameter("customerId", customerId)
         .setParameter("customerEmail", customerEmail)
         .getSingleResult());
    }

    public long countLinkedReviews(Long customerId, String customerEmail) {
        return toLong(entityManager.createQuery(
                "select count(r) from Review r where " +
                        "(r.customerId is not null and r.customerId = :customerId) " +
                        "or (:customerEmail is not null and lower(coalesce(r.customerEmail, '')) = lower(:customerEmail))"
        ).setParameter("customerId", customerId)
         .setParameter("customerEmail", customerEmail)
         .getSingleResult());
    }

    public int deleteOrphanedSampleCustomers() {
        List<Customer> sampleCustomers = entityManager.createQuery(
                "from Customer c where lower(coalesce(c.email, '')) like :sampleEmailSuffix order by c.id desc",
                Customer.class
        ).setParameter("sampleEmailSuffix", SAMPLE_CUSTOMER_EMAIL_SUFFIX)
         .getResultList();

        int deleted = 0;
        for (Customer customer : sampleCustomers) {
            long linkedOrders = countLinkedOrders(customer.getId(), customer.getEmail());
            long linkedReturns = countLinkedReturnRequests(customer.getId());
            long linkedReviews = countLinkedReviews(customer.getId(), customer.getEmail());
            if (linkedOrders > 0 || linkedReturns > 0 || linkedReviews > 0) {
                continue;
            }

            entityManager.remove(customer);
            deleted++;
        }

        entityManager.flush();
        return deleted;
    }

    public boolean permanentlyDeleteCustomer(Long id) {
        Customer customer = entityManager.find(Customer.class, id);
        if (customer == null) {
            return false;
        }

        try {
            entityManager.remove(customer);
            entityManager.flush();
            return true;
        } catch (PersistenceException ex) {
            throw ex;
        }
    }

    public void markCustomerDeleted(Customer customer) {
        if (customer == null) {
            return;
        }

        customer.setStatus("DELETED");
        entityManager.flush();
    }

    public Long countCustomers(LocalDate startDate) {
        return toLong(entityManager.createQuery(
                "select count(c) from Customer c " +
                        "where (:startDate is null or c.registeredAt >= :startDate)"
        ).setParameter("startDate", startDate).getSingleResult());
    }

    public int normalizeNullStatuses() {
        int updated = entityManager.createQuery(
                "update Customer c set c.status = 'ACTIVE' where c.status is null or trim(c.status) = ''"
        ).executeUpdate();
        entityManager.flush();
        return updated;
    }

    private Long toLong(Object value) {
        return value == null ? 0L : ((Number) value).longValue();
    }
}
