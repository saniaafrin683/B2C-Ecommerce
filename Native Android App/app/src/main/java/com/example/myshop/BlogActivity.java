package com.example.myshop;

import android.app.Activity;
import android.content.Intent;
import android.os.Bundle;

import androidx.recyclerview.widget.LinearLayoutManager;
import androidx.recyclerview.widget.RecyclerView;

import com.example.myshop.adapter.BlogAdapter;
import com.example.myshop.model.BlogPost;

import java.util.ArrayList;
import java.util.List;

public class BlogActivity extends Activity {

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        ThemeManager.applyTheme(this);
        setContentView(R.layout.activity_blog);
        bindTopBar();
        setupBlogList();
        setupBottomNavigation();
    }

    private void bindTopBar() {
        findViewById(R.id.blogBackButton).setOnClickListener(view -> finish());
        findViewById(R.id.blogCartButton).setOnClickListener(view -> startActivity(new Intent(this, CartActivity.class)));
    }

    private void setupBlogList() {
        RecyclerView recyclerView = findViewById(R.id.blogRecyclerView);
        recyclerView.setLayoutManager(new LinearLayoutManager(this));
        recyclerView.setAdapter(new BlogAdapter(createDemoBlogPosts(), this::openBlogDetails));
    }

    private void setupBottomNavigation() {
        findViewById(R.id.navHome).setOnClickListener(view -> startActivity(new Intent(this, HomeActivity.class)));
        findViewById(R.id.navBrands).setOnClickListener(view -> {
            Intent intent = new Intent(this, ProductActivity.class);
            intent.putExtra(ProductActivity.EXTRA_TITLE, "Brands");
            startActivity(intent);
        });
        findViewById(R.id.navCategories).setOnClickListener(view -> startActivity(new Intent(this, CategoryActivity.class)));
        findViewById(R.id.navBlog).setOnClickListener(view -> findViewById(R.id.blogRecyclerView).scrollTo(0, 0));
    }

    private void openBlogDetails(BlogPost blogPost) {
        Intent intent = new Intent(this, BlogDetailsActivity.class);
        intent.putExtra(BlogDetailsActivity.EXTRA_TITLE, blogPost.getTitle());
        intent.putExtra(BlogDetailsActivity.EXTRA_DESCRIPTION, blogPost.getShortDescription());
        intent.putExtra(BlogDetailsActivity.EXTRA_CONTENT, blogPost.getContent());
        intent.putExtra(BlogDetailsActivity.EXTRA_DATE, blogPost.getDate());
        intent.putExtra(BlogDetailsActivity.EXTRA_CATEGORY, blogPost.getCategory());
        intent.putExtra(BlogDetailsActivity.EXTRA_IMAGE_URL, blogPost.getImageUrl());
        intent.putExtra(BlogDetailsActivity.EXTRA_IMAGE_RES_ID, blogPost.getImageResId());
        startActivity(intent);
    }

    private List<BlogPost> createDemoBlogPosts() {
        List<BlogPost> posts = new ArrayList<>();
        posts.add(new BlogPost(
                1,
                "How to Build a Capsule Wardrobe",
                "A simple guide to choosing versatile pieces that work across seasons.",
                "Start with neutral basics, add two or three accent colors, and choose pieces that can be layered easily. A capsule wardrobe helps you buy with intent, repeat outfits confidently, and keep your daily styling routine fast.",
                "Jun 20, 2026",
                "Style Guide",
                "/uploads/product-images/01c3870b-9bb2-4545-9541-9b8e7aa1709e.jpeg",
                R.drawable.ic_product_placeholder
        ));
        posts.add(new BlogPost(
                2,
                "Summer Fabrics That Feel Better",
                "Cotton, linen, and lighter blends can keep everyday outfits comfortable.",
                "For warm days, look for breathable fabrics and relaxed fits. Cotton tees, linen shirts, and soft blends are easy to style with denim, skirts, or trousers without adding weight.",
                "Jun 18, 2026",
                "Fashion Tips",
                "/uploads/product-images/023ec171-7712-4e72-81c5-d03f3ad8ffef.jpg",
                R.drawable.ic_product_placeholder
        ));
        posts.add(new BlogPost(
                3,
                "Care Tips for Longer Lasting Clothes",
                "Small washing and storage habits can protect color, shape, and texture.",
                "Turn darker garments inside out before washing, avoid overcrowding the machine, and dry delicate fabrics away from direct heat. Fold knits and hang structured pieces to keep their shape.",
                "Jun 15, 2026",
                "Care",
                "/uploads/product-images/0cddc30b-d2eb-4fdf-86d5-ef897cc06c34.webp",
                R.drawable.ic_product_placeholder
        ));
        return posts;
    }
}
