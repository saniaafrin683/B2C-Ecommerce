package com.styleora.controller;

import java.util.List;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import com.styleora.model.Warehouse;
import com.styleora.service.WarehouseService;

@RestController
@RequestMapping("/warehouses")
public class WarehouseController {

    @Autowired
    private WarehouseService warehouseService;

    @PostMapping("/create")
    public String createWarehouse(@RequestBody Warehouse warehouse) {
        warehouse.setId(null);

        warehouseService.saveWarehouse(warehouse);

        return "Warehouse created successfully";
    }

    @GetMapping("/list")
    public List<Warehouse> getAllWarehouses() {

        return warehouseService.getAllWarehouses();
    }

    @GetMapping("/{id}")
    public Warehouse getWarehouseById(@PathVariable Long id) {

        return warehouseService.getWarehouseById(id);
    }

    @PutMapping("/update")
    public String updateWarehouse(@RequestBody Warehouse warehouse) {

        warehouseService.updateWarehouse(warehouse);

        return "Warehouse updated successfully";
    }

    @DeleteMapping("/delete/{id}")
    public String deleteWarehouse(@PathVariable Long id) {

        warehouseService.deleteWarehouse(id);

        return "Warehouse deleted successfully";
    }
}
