package com.example.myshop.model;

import java.util.ArrayList;
import java.util.List;

public class ProductPageResponse {
    private List<Product> content = new ArrayList<>();
    private long totalElements;
    private int totalPages;
    private int page;
    private int size;
    private String sortBy;
    private String sortDir;

    public List<Product> getContent() {
        return content == null ? new ArrayList<>() : content;
    }

    public long getTotalElements() {
        return totalElements;
    }

    public int getTotalPages() {
        return totalPages;
    }

    public int getPage() {
        return page;
    }

    public int getSize() {
        return size;
    }

    public String getSortBy() {
        return sortBy;
    }

    public String getSortDir() {
        return sortDir;
    }
}
