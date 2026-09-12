package com.styleora.dto;

import com.fasterxml.jackson.annotation.JsonAlias;

public class ShipmentStatusUpdateRequest {

    @JsonAlias({"status"})
    private String shipmentStatus;

    public ShipmentStatusUpdateRequest() {
    }

    public String getShipmentStatus() {
        return shipmentStatus;
    }

    public void setShipmentStatus(String shipmentStatus) {
        this.shipmentStatus = shipmentStatus;
    }
}
