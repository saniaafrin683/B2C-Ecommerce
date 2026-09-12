package com.styleora.model;

import jakarta.persistence.*;

@Entity
@Table(name = "warehouses")
public class Warehouse {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    private String warehouseId;
    private String warehouseName;
    private String location;
    private String manager;
    private String contactNumber;
    private Integer stockAvailable;
    private Integer stockShipping;
    private Double warehouseRevenue;

    public Warehouse() {
    }

    public Long getId() {
        return id;
    }

    public String getWarehouseId() {
        return warehouseId;
    }

    public void setWarehouseId(String warehouseId) {
        this.warehouseId = warehouseId;
    }

    public String getWarehouseName() {
        return warehouseName;
    }

    public void setWarehouseName(String warehouseName) {
        this.warehouseName = warehouseName;
    }

    public String getLocation() {
        return location;
    }

    public void setLocation(String location) {
        this.location = location;
    }

    public String getManager() {
        return manager;
    }

    public void setManager(String manager) {
        this.manager = manager;
    }

    public String getContactNumber() {
        return contactNumber;
    }

    public void setContactNumber(String contactNumber) {
        this.contactNumber = contactNumber;
    }

    public Integer getStockAvailable() {
        return stockAvailable;
    }

    public void setStockAvailable(Integer stockAvailable) {
        this.stockAvailable = stockAvailable;
    }

    public Integer getStockShipping() {
        return stockShipping;
    }

    public void setStockShipping(Integer stockShipping) {
        this.stockShipping = stockShipping;
    }

    public Double getWarehouseRevenue() {
        return warehouseRevenue;
    }

    public void setWarehouseRevenue(Double warehouseRevenue) {
        this.warehouseRevenue = warehouseRevenue;
    }

    public void setId(Long id) {
        this.id = id;
    }
}