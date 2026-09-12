package com.example.myshop.model;

public class BlogPost {
    private final long id;
    private final String title;
    private final String shortDescription;
    private final String content;
    private final String date;
    private final String category;
    private final String imageUrl;
    private final int imageResId;

    public BlogPost(long id, String title, String shortDescription, String content, String date, String category, String imageUrl, int imageResId) {
        this.id = id;
        this.title = title;
        this.shortDescription = shortDescription;
        this.content = content;
        this.date = date;
        this.category = category;
        this.imageUrl = imageUrl;
        this.imageResId = imageResId;
    }

    public long getId() {
        return id;
    }

    public String getTitle() {
        return title;
    }

    public String getShortDescription() {
        return shortDescription;
    }

    public String getContent() {
        return content;
    }

    public String getDate() {
        return date;
    }

    public String getCategory() {
        return category;
    }

    public String getImageUrl() {
        return imageUrl;
    }

    public int getImageResId() {
        return imageResId;
    }
}
