package com.styleora.controller;

import com.styleora.dto.CurrentStockSummaryDto;
import com.styleora.service.InventoryService;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequestMapping("/inventory")
public class InventoryController {

    private final InventoryService inventoryService;

    public InventoryController(InventoryService inventoryService) {
        this.inventoryService = inventoryService;
    }

    @GetMapping("/current-stock")
    public List<CurrentStockSummaryDto> getCurrentStock() {
        return inventoryService.getCurrentStockSummaries();
    }
}
