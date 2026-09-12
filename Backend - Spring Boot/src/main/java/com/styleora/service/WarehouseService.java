package com.styleora.service;

import java.util.List;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import com.styleora.dao.WarehouseDao;
import com.styleora.model.Warehouse;

@Service
public class WarehouseService {

    @Autowired
    private WarehouseDao warehouseDao;

    public void saveWarehouse(Warehouse warehouse) {

        warehouseDao.saveWarehouse(warehouse);
    }

    public List<Warehouse> getAllWarehouses() {

        return warehouseDao.getAllWarehouses();
    }

    public Warehouse getWarehouseById(Long id) {

        return warehouseDao.getWarehouseById(id);
    }

    public void updateWarehouse(Warehouse warehouse) {

        warehouseDao.updateWarehouse(warehouse);
    }

    public void deleteWarehouse(Long id) {

        warehouseDao.deleteWarehouse(id);
    }
}