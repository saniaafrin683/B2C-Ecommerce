package com.example.myshop;

import android.app.Activity;
import android.os.Bundle;
import android.widget.ImageView;
import android.widget.TextView;

import com.bumptech.glide.Glide;
import com.example.myshop.network.RetrofitClient;

public class BlogDetailsActivity extends Activity {
    public static final String EXTRA_TITLE = "extra_title";
    public static final String EXTRA_DESCRIPTION = "extra_description";
    public static final String EXTRA_CONTENT = "extra_content";
    public static final String EXTRA_DATE = "extra_date";
    public static final String EXTRA_CATEGORY = "extra_category";
    public static final String EXTRA_IMAGE_URL = "extra_image_url";
    public static final String EXTRA_IMAGE_RES_ID = "extra_image_res_id";

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        ThemeManager.applyTheme(this);
        setContentView(R.layout.activity_blog_details);
        bindBlogDetails();
    }

    private void bindBlogDetails() {
        findViewById(R.id.blogDetailsBackButton).setOnClickListener(view -> finish());

        ImageView imageView = findViewById(R.id.blogDetailsImageView);
        TextView titleText = findViewById(R.id.blogDetailsTitleText);
        TextView metaText = findViewById(R.id.blogDetailsMetaText);
        TextView descriptionText = findViewById(R.id.blogDetailsDescriptionText);
        TextView contentText = findViewById(R.id.blogDetailsContentText);

        int fallbackImage = getIntent().getIntExtra(EXTRA_IMAGE_RES_ID, R.drawable.ic_product_placeholder);
        Glide.with(this)
                .load(buildImageUrl(getIntent().getStringExtra(EXTRA_IMAGE_URL)))
                .placeholder(fallbackImage)
                .error(fallbackImage)
                .centerCrop()
                .into(imageView);
        titleText.setText(getIntent().getStringExtra(EXTRA_TITLE));
        metaText.setText(buildMeta(getIntent().getStringExtra(EXTRA_CATEGORY), getIntent().getStringExtra(EXTRA_DATE)));
        descriptionText.setText(getIntent().getStringExtra(EXTRA_DESCRIPTION));
        contentText.setText(getIntent().getStringExtra(EXTRA_CONTENT));
    }

    private String buildImageUrl(String imageUrl) {
        if (imageUrl == null || imageUrl.trim().isEmpty()) {
            return null;
        }
        String value = imageUrl.trim();
        if (value.startsWith("http://") || value.startsWith("https://") || value.startsWith("data:")) {
            return value;
        }
        return RetrofitClient.getBaseUrl() + value.replaceFirst("^/+", "");
    }

    private String buildMeta(String category, String date) {
        String safeCategory = category == null ? "Blog" : category;
        String safeDate = date == null ? "" : date;
        return safeCategory + " / " + safeDate;
    }
}
