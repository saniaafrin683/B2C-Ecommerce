package com.styleora.model;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;

@Entity
public class Category {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    private String categoryTitle;
    private String createdBy;
    private Integer stock;
    private String tagId;

    @Column(length = 2000)
    private String description;

    @Column(columnDefinition = "LONGTEXT")
    private String imageUrl;

    public Category() {
    }

    public Long getId() {
        return id;
    }

    public String getCategoryTitle() {
        return categoryTitle;
    }

    public String getCreatedBy() {
        return createdBy;
    }

    public Integer getStock() {
        return stock;
    }

    public String getTagId() {
        return tagId;
    }

    public String getDescription() {
        return description;
    }

    public String getImageUrl() {
        return imageUrl;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public void setCategoryTitle(String categoryTitle) {
        this.categoryTitle = categoryTitle;
    }

    public void setCreatedBy(String createdBy) {
        this.createdBy = createdBy;
    }

    public void setStock(Integer stock) {
        this.stock = stock;
    }

    public void setTagId(String tagId) {
        this.tagId = tagId;
    }

    public void setDescription(String description) {
        this.description = description;
    }

    public void setImageUrl(String imageUrl) {
        this.imageUrl = imageUrl;
    }
}