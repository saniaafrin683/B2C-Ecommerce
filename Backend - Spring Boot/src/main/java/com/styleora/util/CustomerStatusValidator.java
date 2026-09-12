package com.styleora.util;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.util.StringUtils;

import java.util.Locale;
import java.util.Set;

public final class CustomerStatusValidator {
    private static final Logger LOGGER = LoggerFactory.getLogger(CustomerStatusValidator.class);

    public static final String STATUS_ACTIVE = "ACTIVE";
    public static final String STATUS_INACTIVE = "INACTIVE";
    public static final String STATUS_SUSPENDED = "SUSPENDED";
    public static final String STATUS_DELETED = "DELETED";

    private static final Set<String> VALID_STATUSES = Set.of(
            STATUS_ACTIVE,
            STATUS_INACTIVE,
            STATUS_SUSPENDED,
            STATUS_DELETED
    );

    private CustomerStatusValidator() {
    }

    public static String normalize(String status) {
        return normalize(status, null);
    }

    public static String normalize(String status, String context) {
        if (!StringUtils.hasText(status)) {
            return STATUS_ACTIVE;
        }

        String normalizedStatus = status.trim().toUpperCase(Locale.ROOT);
        if (VALID_STATUSES.contains(normalizedStatus)) {
            return normalizedStatus;
        }

        LOGGER.warn("Customer status defaulted to ACTIVE for invalid value='{}'{}", status, formatContext(context));
        return STATUS_ACTIVE;
    }

    private static String formatContext(String context) {
        return StringUtils.hasText(context) ? ", context=" + context.trim() : "";
    }
}
