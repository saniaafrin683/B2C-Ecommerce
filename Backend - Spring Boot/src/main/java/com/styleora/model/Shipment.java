package com.styleora.model;

import com.fasterxml.jackson.annotation.JsonAlias;
import com.fasterxml.jackson.annotation.JsonFormat;
import com.fasterxml.jackson.annotation.JsonProperty;
import com.fasterxml.jackson.annotation.JsonSetter;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import jakarta.persistence.Transient;

import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.time.format.DateTimeParseException;
import java.util.List;

@Entity
@Table(name = "shipments")
public class Shipment {

    private static final List<DateTimeFormatter> SUPPORTED_DATE_TIME_FORMATS = List.of(
            DateTimeFormatter.ISO_LOCAL_DATE_TIME,
            DateTimeFormatter.ofPattern("yyyy-MM-dd'T'HH:mm")
    );

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "order_id")
    private Long orderId;

    @Transient
    private String orderNumber;

    @Column(name = "shipping_method_id")
    private Long shippingMethodId;

    @Column(name = "tracking_number")
    private String trackingNumber;

    @Column(name = "courier_name")
    private String courierName;

    @Column(name = "status")
    private String status;

    @Column(name = "dispatch_date")
    @JsonFormat(pattern = "yyyy-MM-dd'T'HH:mm:ss")
    private LocalDateTime dispatchDate;

    @Column(name = "estimated_delivery_date")
    @JsonFormat(pattern = "yyyy-MM-dd'T'HH:mm:ss")
    private LocalDateTime estimatedDeliveryDate;

    @Column(name = "delivered_date")
    @JsonFormat(pattern = "yyyy-MM-dd'T'HH:mm:ss")
    private LocalDateTime deliveredDate;

    @Column(name = "remarks", length = 2000)
    private String remarks;

    public Shipment() {
    }

    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public Long getOrderId() {
        return orderId;
    }

    public void setOrderId(Long orderId) {
        this.orderId = orderId;
    }

    public String getOrderNumber() {
        return orderNumber;
    }

    public void setOrderNumber(String orderNumber) {
        this.orderNumber = orderNumber;
    }

    public Long getShippingMethodId() {
        return shippingMethodId;
    }

    public void setShippingMethodId(Long shippingMethodId) {
        this.shippingMethodId = shippingMethodId;
    }

    public String getTrackingNumber() {
        return trackingNumber;
    }

    public void setTrackingNumber(String trackingNumber) {
        this.trackingNumber = trackingNumber;
    }

    public String getCourierName() {
        return courierName;
    }

    public void setCourierName(String courierName) {
        this.courierName = courierName;
    }

    public String getStatus() {
        return status;
    }

    @JsonAlias({"shipmentStatus"})
    public void setStatus(String status) {
        this.status = status;
    }

    public LocalDateTime getDispatchDate() {
        return dispatchDate;
    }

    @JsonAlias({"shippedDate"})
    public void setDispatchDate(LocalDateTime dispatchDate) {
        this.dispatchDate = dispatchDate;
    }

    @JsonSetter("dispatchDate")
    public void setDispatchDateFromJson(String dispatchDate) {
        this.dispatchDate = parseDateTime(dispatchDate, "dispatchDate");
    }

    public LocalDateTime getEstimatedDeliveryDate() {
        return estimatedDeliveryDate;
    }

    public void setEstimatedDeliveryDate(LocalDateTime estimatedDeliveryDate) {
        this.estimatedDeliveryDate = estimatedDeliveryDate;
    }

    @JsonSetter("estimatedDeliveryDate")
    public void setEstimatedDeliveryDateFromJson(String estimatedDeliveryDate) {
        this.estimatedDeliveryDate = parseDateTime(estimatedDeliveryDate, "estimatedDeliveryDate");
    }

    public LocalDateTime getDeliveredDate() {
        return deliveredDate;
    }

    public void setDeliveredDate(LocalDateTime deliveredDate) {
        this.deliveredDate = deliveredDate;
    }

    @JsonSetter("deliveredDate")
    public void setDeliveredDateFromJson(String deliveredDate) {
        this.deliveredDate = parseDateTime(deliveredDate, "deliveredDate");
    }

    public String getRemarks() {
        return remarks;
    }

    public void setRemarks(String remarks) {
        this.remarks = remarks;
    }

    @JsonProperty("shipmentStatus")
    public String getShipmentStatus() {
        return status;
    }

    @JsonProperty("shipmentStatus")
    public void setShipmentStatus(String shipmentStatus) {
        this.status = shipmentStatus;
    }

    @JsonProperty("shippedDate")
    public LocalDateTime getShippedDate() {
        return dispatchDate;
    }

    @JsonProperty("shippedDate")
    public void setShippedDate(LocalDateTime shippedDate) {
        this.dispatchDate = shippedDate;
    }

    @JsonSetter("shippedDate")
    public void setShippedDateFromJson(String shippedDate) {
        this.dispatchDate = parseDateTime(shippedDate, "shippedDate");
    }

    private LocalDateTime parseDateTime(String value, String fieldName) {

        if (value == null || value.trim().isEmpty()) {
            return null;
        }

        String trimmedValue = value.trim();

        for (DateTimeFormatter formatter : SUPPORTED_DATE_TIME_FORMATS) {

            try {
                return LocalDateTime.parse(trimmedValue, formatter);
            } catch (DateTimeParseException ignored) {

            }
        }

        throw new IllegalArgumentException(
                fieldName + " must use yyyy-MM-dd'T'HH:mm or yyyy-MM-dd'T'HH:mm:ss."
        );
    }
}