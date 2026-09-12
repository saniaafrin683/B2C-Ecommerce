package com.styleora.service;

import com.styleora.dao.CustomerDao;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.CommandLineRunner;
import org.springframework.stereotype.Service;

@Service
public class DataConsistencyStartupService implements CommandLineRunner {

    private static final Logger LOGGER = LoggerFactory.getLogger(DataConsistencyStartupService.class);

    private final CustomerDao customerDao;
    private final ShippingMethodService shippingMethodService;

    public DataConsistencyStartupService(CustomerDao customerDao, ShippingMethodService shippingMethodService) {
        this.customerDao = customerDao;
        this.shippingMethodService = shippingMethodService;
    }

    @Override
    public void run(String... args) {
        int normalizedCustomers = customerDao.normalizeNullStatuses();
        LOGGER.info("Startup customer status cleanup normalized={}", normalizedCustomers);

        int activeShippingMethods = shippingMethodService.getAllShippingMethods().size();
        LOGGER.info("Startup shipping method cleanup activeCount={}", activeShippingMethods);
    }
}
