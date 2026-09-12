package com.example.myshop.model;

import java.math.BigDecimal;

public class CartItem {
    private Long productId;
    private String name;
    private BigDecimal price;
    private BigDecimal discount;
    private String imageUrl;
    private String size;
    private int quantity;
    private int stock;

    public CartItem() {
    }

    public CartItem(Product product, int quantity, String size) {
        this.productId = product.getId();
        this.name = product.getName();
        this.price = product.getPrice();
        this.discount = product.getDiscount();
        this.imageUrl = product.getImageUrl();
        this.size = size;
        this.quantity = quantity;
        this.stock = product.getStock() == null ? 0 : product.getStock();
    }

    public Long getProductId() {
        return productId;
    }

    public String getName() {
        return name;
    }

    public BigDecimal getPrice() {
        return price;
    }

    public BigDecimal getDiscount() {
        return discount;
    }

    public String getImageUrl() {
        return imageUrl;
    }

    public String getSize() {
        return size;
    }

    public int getQuantity() {
        return quantity;
    }

    public int getStock() {
        return stock;
    }

    public void setQuantity(int quantity) {
        this.quantity = Math.max(0, quantity);
    }
}
