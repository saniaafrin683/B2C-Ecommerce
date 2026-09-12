package com.styleora.service;

import com.styleora.dao.OrderDao;
import com.styleora.dao.ShipmentDao;
import com.styleora.dao.ShippingMethodDao;
import com.styleora.dto.ShipmentStatusUpdateRequest;
import com.styleora.model.Order;
import com.styleora.model.Shipment;
import com.styleora.model.ShippingMethod;
import com.styleora.security.AuthenticatedUser;
import jakarta.transaction.Transactional;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.util.StringUtils;
import org.springframework.web.server.ResponseStatusException;

import java.time.LocalDateTime;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;

@Service
public class ShipmentService {

    private static final Logger LOGGER = LoggerFactory.getLogger(ShipmentService.class);

    private static final String STATUS_PENDING = "Pending";
    private static final String STATUS_PACKED = "Packed";
    private static final String STATUS_SHIPPED = "Shipped";
    private static final String STATUS_OUT_FOR_DELIVERY = "Out For Delivery";
    private static final String STATUS_DELIVERED = "Delivered";

    private static final String ORDER_STATUS_CONFIRMED = "Confirmed";
    private static final String ORDER_STATUS_PACKED = "Packed";
    private static final String ORDER_STATUS_PROCESSING = "Processing";
    private static final String ORDER_STATUS_SHIPPED = "Shipped";
    private static final String ORDER_STATUS_DELIVERED = "Delivered";

    private static final Map<String, String> STATUS_ALIASES = createStatusAliases();

    private final ShipmentDao shipmentDao;
    private final OrderDao orderDao;
    private final ShippingMethodDao shippingMethodDao;

    public ShipmentService(
            ShipmentDao shipmentDao,
            OrderDao orderDao,
            ShippingMethodDao shippingMethodDao
    ) {
        this.shipmentDao = shipmentDao;
        this.orderDao = orderDao;
        this.shippingMethodDao = shippingMethodDao;
    }

    @Transactional
    public Shipment createShipment(Shipment shipment) {
        Shipment normalizedShipment = requireAndNormalizeShipment(shipment, null);
        ensureNoActiveShipment(normalizedShipment.getOrderId());

        Shipment savedShipment = shipmentDao.saveShipment(normalizedShipment);
        syncOrderOnShipmentChange(savedShipment);
        enrichShipmentOrderNumber(savedShipment);

        return savedShipment;
    }

    public List<Shipment> getAllShipments() {
        List<Shipment> shipments = shipmentDao.getAllShipments();

        for (Shipment shipment : shipments) {
            enrichShipmentOrderNumber(shipment);
        }

        return shipments;
    }

    public Shipment getShipmentById(Long id) {
        Shipment shipment = shipmentDao.getShipmentById(id);
        enrichShipmentOrderNumber(shipment);
        return shipment;
    }

    public Shipment getShipmentByOrderId(Long orderId, AuthenticatedUser authenticatedUser) {
        if (orderId == null || orderId <= 0) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Order id is required.");
        }

        Order order = requireVisibleOrder(orderId, authenticatedUser);

        Shipment shipment = shipmentDao.getLatestShipmentByOrderId(order.getId());

        if (shipment == null) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "Shipment not found.");
        }

        enrichShipmentOrderNumber(shipment);
        return shipment;
    }

    @Transactional
    public Shipment updateShipment(Long id, Shipment shipment) {
        Shipment existingShipment = shipmentDao.getShipmentByIdForUpdate(id);

        if (existingShipment == null) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "Shipment not found.");
        }

        Shipment normalizedShipment = requireAndNormalizeShipment(shipment, existingShipment);
        Shipment updatedShipment = shipmentDao.updateShipment(id, normalizedShipment);

        syncOrderOnShipmentChange(updatedShipment);
        enrichShipmentOrderNumber(updatedShipment);

        return updatedShipment;
    }

    @Transactional
    public Shipment updateShipmentStatus(Long id, ShipmentStatusUpdateRequest request) {
        Shipment existingShipment = shipmentDao.getShipmentByIdForUpdate(id);

        if (existingShipment == null) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "Shipment not found.");
        }

        existingShipment.setShipmentStatus(
                normalizeShipmentStatus(request != null ? request.getShipmentStatus() : null)
        );

        applyLifecycleDates(existingShipment);

        Shipment updatedShipment = shipmentDao.updateShipment(id, existingShipment);

        syncOrderOnShipmentChange(updatedShipment);
        enrichShipmentOrderNumber(updatedShipment);

        return updatedShipment;
    }

    public boolean deleteShipment(Long id) {
        return shipmentDao.deleteShipment(id);
    }

    private Shipment requireAndNormalizeShipment(Shipment shipment, Shipment existingShipment) {
        if (shipment == null) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Shipment payload is required.");
        }

        Long orderId = shipment.getOrderId() != null
                ? shipment.getOrderId()
                : existingShipment != null ? existingShipment.getOrderId() : null;

        if (orderId == null || orderId <= 0) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Order id is required.");
        }

        Order order = orderDao.getOrderByIdFresh(orderId);

        if (order == null) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "Order not found.");
        }

        LOGGER.info(
                "Shipment validation using persisted order state: orderDbId={}, orderReference={}, orderStatus={}",
                order.getId(),
                order.getOrderId(),
                order.getOrderStatus()
        );

        validateOrderEligibleForShipment(order);

        Long shippingMethodId = shipment.getShippingMethodId() != null
                ? shipment.getShippingMethodId()
                : existingShipment != null ? existingShipment.getShippingMethodId() : null;

        if (shippingMethodId == null || shippingMethodId <= 0) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Shipping method is required.");
        }

        ShippingMethod shippingMethod = shippingMethodDao.getShippingMethodById(shippingMethodId);

        if (shippingMethod == null) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "Selected shipping method not found.");
        }

        Shipment normalizedShipment = new Shipment();

        normalizedShipment.setId(existingShipment != null ? existingShipment.getId() : null);
        normalizedShipment.setOrderId(order.getId());
        normalizedShipment.setOrderNumber(order.getOrderId());
        normalizedShipment.setShippingMethodId(shippingMethod.getId());
        normalizedShipment.setTrackingNumber(trimToNull(shipment.getTrackingNumber()));
        normalizedShipment.setCourierName(resolveCourierName(shipment.getCourierName(), shippingMethod.getCourierName()));
        normalizedShipment.setShipmentStatus(normalizeShipmentStatus(shipment.getShipmentStatus()));
        normalizedShipment.setShippedDate(
                resolveDateTime(
                        shipment.getShippedDate(),
                        existingShipment != null ? existingShipment.getShippedDate() : null
                )
        );
        normalizedShipment.setEstimatedDeliveryDate(
                resolveDateTime(
                        shipment.getEstimatedDeliveryDate(),
                        existingShipment != null ? existingShipment.getEstimatedDeliveryDate() : null
                )
        );
        normalizedShipment.setDeliveredDate(
                resolveDateTime(
                        shipment.getDeliveredDate(),
                        existingShipment != null ? existingShipment.getDeliveredDate() : null
                )
        );
        normalizedShipment.setRemarks(trimToNull(shipment.getRemarks()));

        applyLifecycleDates(normalizedShipment);

        return normalizedShipment;
    }

    private void enrichShipmentOrderNumber(Shipment shipment) {
        if (shipment == null || shipment.getOrderId() == null) {
            return;
        }

        Order order = orderDao.getOrderById(shipment.getOrderId());

        if (order != null) {
            shipment.setOrderNumber(order.getOrderId());
        }
    }

    private void ensureNoActiveShipment(Long orderId) {
        Shipment existingShipment = shipmentDao.getLatestShipmentByOrderId(orderId);

        if (existingShipment != null && !STATUS_DELIVERED.equalsIgnoreCase(existingShipment.getShipmentStatus())) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "An active shipment already exists for this order.");
        }
    }

    private Order requireVisibleOrder(Long orderId, AuthenticatedUser authenticatedUser) {
        if (authenticatedUser != null && authenticatedUser.hasRole("CUSTOMER")) {
            Order customerOrder = orderDao.getOrderByIdAndCustomerEmail(orderId, authenticatedUser.getEmail());

            if (customerOrder == null) {
                throw new ResponseStatusException(HttpStatus.NOT_FOUND, "Order not found.");
            }

            return customerOrder;
        }

        Order order = orderDao.getOrderById(orderId);

        if (order == null) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "Order not found.");
        }

        return order;
    }

    private void syncOrderOnShipmentChange(Shipment shipment) {
        if (shipment == null || shipment.getOrderId() == null) {
            return;
        }

        if (STATUS_DELIVERED.equalsIgnoreCase(shipment.getShipmentStatus())) {
            orderDao.updateOrderStatus(shipment.getOrderId(), STATUS_DELIVERED);
        }
    }

    private void applyLifecycleDates(Shipment shipment) {
        if (shipment == null) {
            return;
        }

        String shipmentStatus = shipment.getShipmentStatus();

        if ((STATUS_SHIPPED.equalsIgnoreCase(shipmentStatus)
                || STATUS_OUT_FOR_DELIVERY.equalsIgnoreCase(shipmentStatus)
                || STATUS_DELIVERED.equalsIgnoreCase(shipmentStatus))
                && shipment.getShippedDate() == null) {
            shipment.setShippedDate(LocalDateTime.now());
        }

        if (STATUS_DELIVERED.equalsIgnoreCase(shipmentStatus)) {
            if (shipment.getDeliveredDate() == null) {
                shipment.setDeliveredDate(LocalDateTime.now());
            }
        } else {
            shipment.setDeliveredDate(null);
        }
    }

    private void validateOrderEligibleForShipment(Order order) {
        String orderStatus = trimToNull(order != null ? order.getOrderStatus() : null);

        if (!ORDER_STATUS_CONFIRMED.equalsIgnoreCase(orderStatus)
                && !ORDER_STATUS_PACKED.equalsIgnoreCase(orderStatus)
                && !ORDER_STATUS_PROCESSING.equalsIgnoreCase(orderStatus)
                && !ORDER_STATUS_SHIPPED.equalsIgnoreCase(orderStatus)
                && !ORDER_STATUS_DELIVERED.equalsIgnoreCase(orderStatus)) {
            LOGGER.warn(
                    "Shipment validation rejected orderDbId={}, orderReference={}, actualOrderStatus={}",
                    order != null ? order.getId() : null,
                    order != null ? order.getOrderId() : null,
                    orderStatus
            );
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST,
                    "Shipment can be created only after order is Confirmed, Packed, Processing, Shipped, or Delivered. Actual order status: "
                            + (orderStatus != null ? orderStatus : "null")
            );
        }
    }

    private LocalDateTime resolveDateTime(LocalDateTime providedValue, LocalDateTime existingValue) {
        return providedValue != null ? providedValue : existingValue;
    }

    private String trimToNull(String value) {
        return StringUtils.hasText(value) ? value.trim() : null;
    }

    private String resolveCourierName(String shipmentCourierName, String shippingMethodCourierName) {
        String explicitCourierName = trimToNull(shipmentCourierName);

        if (explicitCourierName != null) {
            return explicitCourierName;
        }

        return trimToNull(shippingMethodCourierName);
    }

    private String normalizeShipmentStatus(String shipmentStatus) {
        String normalizedStatus = trimToNull(shipmentStatus);

        if (!StringUtils.hasText(normalizedStatus)) {
            return STATUS_PENDING;
        }

        String canonicalStatus = STATUS_ALIASES.get(normalizedStatus.toLowerCase(Locale.ROOT));

        if (canonicalStatus == null) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Invalid shipment status.");
        }

        return canonicalStatus;
    }

    private static Map<String, String> createStatusAliases() {
        Map<String, String> aliases = new LinkedHashMap<>();

        aliases.put("pending", STATUS_PENDING);
        aliases.put("created", STATUS_PENDING);
        aliases.put("packed", STATUS_PACKED);
        aliases.put("confirmed", STATUS_PACKED);
        aliases.put("processing", STATUS_PACKED);
        aliases.put("in progress", STATUS_PACKED);
        aliases.put("shipped", STATUS_SHIPPED);
        aliases.put("in transit", STATUS_SHIPPED);
        aliases.put("out for delivery", STATUS_OUT_FOR_DELIVERY);
        aliases.put("out_for_delivery", STATUS_OUT_FOR_DELIVERY);
        aliases.put("delivered", STATUS_DELIVERED);
        aliases.put("complete", STATUS_DELIVERED);
        aliases.put("completed", STATUS_DELIVERED);

        return aliases;
    }
}
