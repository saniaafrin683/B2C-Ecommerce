package com.styleora.dto;

public class CurrentStockSummaryDto {

    private Long productId;
    private String productName;
    private String category;
    private Integer currentStock;
    private Long totalSold;
    private Long totalPurchased;
    private String stockStatus;

    public CurrentStockSummaryDto() {
    }

    public CurrentStockSummaryDto(Long productId, String productName, String category, Integer currentStock, Long totalSold, Long totalPurchased) {
        this.productId = productId;
        this.productName = productName;
        this.category = category;
        this.currentStock = currentStock == null ? 0 : currentStock;
        this.totalSold = totalSold == null ? 0L : totalSold;
        this.totalPurchased = totalPurchased == null ? 0L : totalPurchased;
        this.stockStatus = resolveStockStatus(this.currentStock);
    }

    public Long getProductId() {
        return productId;
    }

    public void setProductId(Long productId) {
        this.productId = productId;
    }

    public String getProductName() {
        return productName;
    }

    public void setProductName(String productName) {
        this.productName = productName;
    }

    public String getCategory() {
        return category;
    }

    public void setCategory(String category) {
        this.category = category;
    }

    public Integer getCurrentStock() {
        return currentStock;
    }

    public void setCurrentStock(Integer currentStock) {
        this.currentStock = currentStock == null ? 0 : currentStock;
        this.stockStatus = resolveStockStatus(this.currentStock);
    }

    public Long getTotalSold() {
        return totalSold;
    }

    public void setTotalSold(Long totalSold) {
        this.totalSold = totalSold == null ? 0L : totalSold;
    }

    public Long getTotalPurchased() {
        return totalPurchased;
    }

    public void setTotalPurchased(Long totalPurchased) {
        this.totalPurchased = totalPurchased == null ? 0L : totalPurchased;
    }

    public String getStockStatus() {
        return stockStatus;
    }

    public void setStockStatus(String stockStatus) {
        this.stockStatus = stockStatus;
    }

    private String resolveStockStatus(Integer stock) {
        int normalizedStock = stock == null ? 0 : stock;
        if (normalizedStock <= 0) {
            return "Out of Stock";
        }
        if (normalizedStock < 10) {
            return "Low Stock";
        }
        return "In Stock";
    }
}
