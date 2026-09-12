package com.styleora.service;

import com.styleora.dao.ShippingMethodDao;
import com.styleora.model.ShippingMethod;
import jakarta.transaction.Transactional;
import org.springframework.stereotype.Service;
import org.springframework.util.StringUtils;

import java.util.ArrayList;
import java.util.Comparator;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;

@Service
public class ShippingMethodService {

    private final ShippingMethodDao shippingMethodDao;

    public ShippingMethodService(ShippingMethodDao shippingMethodDao) {
        this.shippingMethodDao = shippingMethodDao;
    }

    public ShippingMethod createShippingMethod(ShippingMethod shippingMethod) {
        normalizeShippingMethod(shippingMethod);
        return shippingMethodDao.saveShippingMethod(shippingMethod);
    }

    @Transactional
    public List<ShippingMethod> getAllShippingMethods() {
        List<ShippingMethod> shippingMethods = shippingMethodDao.getAllShippingMethods();
        cleanupDuplicateShippingMethods(shippingMethods);

        List<ShippingMethod> activeShippingMethods = shippingMethodDao.getActiveShippingMethods();
        if (activeShippingMethods.isEmpty()) {
            seedDefaultShippingMethods();
            activeShippingMethods = shippingMethodDao.getActiveShippingMethods();
        }

        return activeShippingMethods;
    }

    public ShippingMethod getShippingMethodById(Long id) {
        return shippingMethodDao.getShippingMethodById(id);
    }

    public ShippingMethod updateShippingMethod(Long id, ShippingMethod shippingMethod) {
        ShippingMethod existingShippingMethod = shippingMethodDao.getShippingMethodById(id);
        if (existingShippingMethod == null) {
            return null;
        }

        normalizeShippingMethod(shippingMethod);
        return shippingMethodDao.updateShippingMethod(id, shippingMethod);
    }

    public boolean deleteShippingMethod(Long id) {
        return shippingMethodDao.deleteShippingMethod(id);
    }

    private void normalizeShippingMethod(ShippingMethod shippingMethod) {
        if (shippingMethod == null) {
            return;
        }

        shippingMethod.setName(trimToNull(shippingMethod.getName()));
        shippingMethod.setDescription(trimToNull(shippingMethod.getDescription()));
        shippingMethod.setCoverageArea(trimToNull(shippingMethod.getCoverageArea()));
        shippingMethod.setCourierName(trimToNull(shippingMethod.getCourierName()));
        shippingMethod.setStatus(normalizeStatus(shippingMethod.getStatus()));

        if (shippingMethod.getIsFreeShipping() == null) {
            shippingMethod.setIsFreeShipping(false);
        }

        if (shippingMethod.getSortOrder() == null) {
            shippingMethod.setSortOrder(0);
        }

        if (shippingMethod.getMinOrderAmount() == null) {
            shippingMethod.setMinOrderAmount(0.0);
        }

        if (shippingMethod.getMaxWeightKg() == null) {
            shippingMethod.setMaxWeightKg(0.0);
        }
    }

    private void cleanupDuplicateShippingMethods(List<ShippingMethod> shippingMethods) {
        Map<String, List<ShippingMethod>> methodsByName = new LinkedHashMap<>();

        for (ShippingMethod shippingMethod : shippingMethods) {
            String normalizedName = normalizeName(shippingMethod.getName());
            if (!StringUtils.hasText(normalizedName)) {
                continue;
            }

            normalizeShippingMethod(shippingMethod);
            methodsByName.computeIfAbsent(normalizedName, key -> new ArrayList<>()).add(shippingMethod);
        }

        boolean changed = false;
        for (List<ShippingMethod> duplicates : methodsByName.values()) {
            if (duplicates.size() <= 1) {
                continue;
            }

            duplicates.sort(Comparator.comparing(ShippingMethod::getId, Comparator.nullsLast(Long::compareTo)));
            ShippingMethod keeper = duplicates.get(0);
            keeper.setStatus("ACTIVE");

            for (int index = 1; index < duplicates.size(); index++) {
                ShippingMethod duplicate = duplicates.get(index);
                if (!"INACTIVE".equalsIgnoreCase(duplicate.getStatus())) {
                    duplicate.setStatus("INACTIVE");
                    changed = true;
                }
            }
        }

        if (changed) {
            shippingMethodDao.flush();
        }
    }

    private void seedDefaultShippingMethods() {
        List<ShippingMethod> defaults = List.of(
                buildDefaultMethod("Standard Delivery", "Reliable delivery for regular orders.", "Nationwide", "Styleora Standard", 60.0, 2, 1),
                buildDefaultMethod("Express Delivery", "Faster delivery for priority orders.", "Metro Areas", "Styleora Express", 120.0, 1, 2),
                buildDefaultMethod("Same Day Delivery", "Same day fulfillment where available.", "Selected City Zones", "Styleora Same Day", 180.0, 0, 3)
        );

        for (ShippingMethod shippingMethod : defaults) {
            shippingMethodDao.saveShippingMethod(shippingMethod);
        }
    }

    private ShippingMethod buildDefaultMethod(
            String name,
            String description,
            String coverageArea,
            String courierName,
            Double cost,
            Integer estimatedDays,
            Integer sortOrder
    ) {
        ShippingMethod shippingMethod = new ShippingMethod();
        shippingMethod.setName(name);
        shippingMethod.setDescription(description);
        shippingMethod.setCoverageArea(coverageArea);
        shippingMethod.setCourierName(courierName);
        shippingMethod.setCost(cost);
        shippingMethod.setMinOrderAmount(0.0);
        shippingMethod.setMaxWeightKg(0.0);
        shippingMethod.setIsFreeShipping(false);
        shippingMethod.setEstimatedDays(estimatedDays);
        shippingMethod.setSortOrder(sortOrder);
        shippingMethod.setStatus("ACTIVE");
        return shippingMethod;
    }

    private String normalizeName(String value) {
        String trimmedValue = trimToNull(value);
        return trimmedValue == null ? null : trimmedValue.toLowerCase(Locale.ROOT);
    }

    private String normalizeStatus(String value) {
        String normalizedValue = trimToNull(value);
        if (normalizedValue == null) {
            return "ACTIVE";
        }

        return "INACTIVE".equalsIgnoreCase(normalizedValue) ? "INACTIVE" : "ACTIVE";
    }

    private String trimToNull(String value) {
        return StringUtils.hasText(value) ? value.trim() : null;
    }
}
