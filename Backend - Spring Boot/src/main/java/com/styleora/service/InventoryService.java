package com.styleora.service;

import com.styleora.dao.InventoryDao;
import com.styleora.dto.CurrentStockSummaryDto;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
public class InventoryService {

    private final InventoryDao inventoryDao;

    public InventoryService(InventoryDao inventoryDao) {
        this.inventoryDao = inventoryDao;
    }

    public List<CurrentStockSummaryDto> getCurrentStockSummaries() {
        return inventoryDao.getCurrentStockSummaries();
    }
}
