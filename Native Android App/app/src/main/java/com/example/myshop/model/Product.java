package com.example.myshop.model;

import java.math.BigDecimal;
import java.util.List;

public class Product {
    private Long id;
    private String name;
    private String category;
    private Long subCategoryId;
    private String subCategory;
    private String brand;
    private String weight;
    private String gender;
    private String description;
    private String tagNumber;
    private Integer stock;
    private String tag;
    private BigDecimal price;
    private BigDecimal discount;
    private BigDecimal tax;
    private String imageUrl;
    private List<String> imageUrls;
    private List<String> images;
    private List<String> galleryImages;
    private String size;
    private String color;
    private String material;
    private String fabric;
    private String length;
    private String washCare;
    private String createdAt;
    private String updatedAt;

    public Long getId() {
        return id;
    }

    public String getName() {
        return name;
    }

    public String getCategory() {
        return category;
    }

    public Long getSubCategoryId() {
        return subCategoryId;
    }

    public String getSubCategory() {
        return subCategory;
    }

    public String getBrand() {
        return brand;
    }

    public String getWeight() {
        return weight;
    }

    public String getGender() {
        return gender;
    }

    public String getDescription() {
        return description;
    }

    public String getTagNumber() {
        return tagNumber;
    }

    public Integer getStock() {
        return stock;
    }

    public String getTag() {
        return tag;
    }

    public BigDecimal getPrice() {
        return price;
    }

    public BigDecimal getDiscount() {
        return discount;
    }

    public BigDecimal getTax() {
        return tax;
    }

    public String getImageUrl() {
        return imageUrl;
    }

    public List<String> getImageUrls() {
        return imageUrls;
    }

    public List<String> getImages() {
        return images;
    }

    public List<String> getGalleryImages() {
        return galleryImages;
    }

    public String getSize() {
        return size;
    }

    public String getColor() {
        return color;
    }

    public String getMaterial() {
        return material;
    }

    public String getFabric() {
        return fabric;
    }

    public String getLength() {
        return length;
    }

    public String getWashCare() {
        return washCare;
    }

    public String getCreatedAt() {
        return createdAt;
    }

    public String getUpdatedAt() {
        return updatedAt;
    }
}
