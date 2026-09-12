package com.example.myshop;

import android.app.Activity;
import android.os.Bundle;
import android.graphics.Typeface;
import android.view.Gravity;
import android.view.View;
import android.widget.Button;
import android.widget.LinearLayout;
import android.widget.ProgressBar;
import android.widget.TextView;
import android.widget.Toast;

import androidx.viewpager2.widget.ViewPager2;

import com.example.myshop.adapter.ProductImageAdapter;
import com.example.myshop.model.Product;
import com.example.myshop.model.Review;
import com.example.myshop.network.RetrofitClient;
import com.example.myshop.storage.CartManager;
import com.example.myshop.storage.WishlistManager;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.util.ArrayList;
import java.util.List;

import retrofit2.Call;
import retrofit2.Callback;
import retrofit2.Response;

public class ProductDetailsActivity extends Activity {
    public static final String EXTRA_PRODUCT_ID = "product_id";

    private ProgressBar progressBar;
    private View contentView;
    private Product product;
    private TextView wishlistButton;
    private ViewPager2 imagePager;
    private LinearLayout dotsContainer;
    private LinearLayout reviewsContainer;
    private TextView reviewsSummaryText;
    private TextView reviewsEmptyText;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        ThemeManager.applyTheme(this);
        setContentView(R.layout.activity_product_details);

        progressBar = findViewById(R.id.detailsProgressBar);
        contentView = findViewById(R.id.detailsContent);
        wishlistButton = findViewById(R.id.detailsWishlistButton);
        imagePager = findViewById(R.id.detailsImagePager);
        dotsContainer = findViewById(R.id.detailsDotsContainer);
        reviewsContainer = findViewById(R.id.detailsReviewsContainer);
        reviewsSummaryText = findViewById(R.id.detailsReviewsSummaryText);
        reviewsEmptyText = findViewById(R.id.detailsReviewsEmptyText);
        findViewById(R.id.backButton).setOnClickListener(view -> finish());

        long productId = getIntent().getLongExtra(EXTRA_PRODUCT_ID, 0);
        if (productId <= 0) {
            Toast.makeText(this, "Product not found.", Toast.LENGTH_SHORT).show();
            finish();
            return;
        }
        loadProduct(productId);
    }

    private void loadProduct(long productId) {
        progressBar.setVisibility(View.VISIBLE);
        contentView.setVisibility(View.GONE);
        RetrofitClient.getApiService().getProduct(productId).enqueue(new Callback<Product>() {
            @Override
            public void onResponse(Call<Product> call, Response<Product> response) {
                progressBar.setVisibility(View.GONE);
                if (!response.isSuccessful() || response.body() == null) {
                    Toast.makeText(ProductDetailsActivity.this, "Unable to load product.", Toast.LENGTH_SHORT).show();
                    finish();
                    return;
                }
                product = response.body();
                bindProduct();
            }

            @Override
            public void onFailure(Call<Product> call, Throwable throwable) {
                progressBar.setVisibility(View.GONE);
                Toast.makeText(ProductDetailsActivity.this, "Cannot connect to server.", Toast.LENGTH_SHORT).show();
                finish();
            }
        });
    }

    private void bindProduct() {
        contentView.setVisibility(View.VISIBLE);
        TextView nameText = findViewById(R.id.detailsNameText);
        TextView metaText = findViewById(R.id.detailsMetaText);
        TextView priceText = findViewById(R.id.detailsPriceText);
        TextView discountText = findViewById(R.id.detailsDiscountText);
        TextView stockText = findViewById(R.id.detailsStockText);
        TextView descriptionText = findViewById(R.id.detailsDescriptionText);
        TextView ratingText = findViewById(R.id.detailsRatingText);
        Button addButton = findViewById(R.id.detailsAddToBagButton);

        List<String> galleryImages = buildGalleryImages();
        imagePager.setAdapter(new ProductImageAdapter(galleryImages));
        createDots(galleryImages.size(), 0);
        imagePager.registerOnPageChangeCallback(new ViewPager2.OnPageChangeCallback() {
            @Override
            public void onPageSelected(int position) {
                createDots(galleryImages.size(), position);
            }
        });

        nameText.setText(value(product.getName(), "Styleora Product"));
        metaText.setText(buildMeta());
        priceText.setText(formatPrice(getDiscountedPrice(product.getPrice(), product.getDiscount())));
        ratingText.setText("★ 4.8");
        discountText.setText(product.getDiscount() != null && product.getDiscount().signum() > 0
                ? product.getDiscount().setScale(0, RoundingMode.HALF_UP).toPlainString() + "% OFF"
                : "New Arrival");
        stockText.setText((product.getStock() == null ? 0 : product.getStock()) > 0 ? "In stock" : "Out of stock");
        descriptionText.setText(value(product.getDescription(), "Premium fashion piece curated for the Styleora shopping experience."));
        wishlistButton.setText(new WishlistManager(this).contains(product.getId()) ? "♥" : "♡");

        wishlistButton.setOnClickListener(view -> {
            boolean added = new WishlistManager(this).toggle(product);
            wishlistButton.setText(added ? "♥" : "♡");
            Toast.makeText(this, added ? "Added to wishlist" : "Removed from wishlist", Toast.LENGTH_SHORT).show();
        });
        addButton.setOnClickListener(view -> {
            new CartManager(this).addProduct(product, 1, product.getSize());
            Toast.makeText(this, "Added to bag", Toast.LENGTH_SHORT).show();
        });

        findViewById(R.id.writeReviewButton).setOnClickListener(view ->
                Toast.makeText(this, "Reviews can be written from delivered orders.", Toast.LENGTH_LONG).show());
        loadReviews();
    }

    private void loadReviews() {
        if (product == null || product.getId() == null) {
            bindReviews(new ArrayList<>());
            return;
        }
        RetrofitClient.getApiService().getApprovedProductReviews(product.getId(), 20).enqueue(new Callback<List<Review>>() {
            @Override
            public void onResponse(Call<List<Review>> call, Response<List<Review>> response) {
                if (response.isSuccessful() && response.body() != null) {
                    bindReviews(response.body());
                } else {
                    bindReviews(new ArrayList<>());
                }
            }

            @Override
            public void onFailure(Call<List<Review>> call, Throwable throwable) {
                bindReviews(new ArrayList<>());
            }
        });
    }

    private void bindReviews(List<Review> reviews) {
        reviewsContainer.removeAllViews();
        if (reviews == null || reviews.isEmpty()) {
            reviewsSummaryText.setText("No ratings yet");
            reviewsEmptyText.setVisibility(View.VISIBLE);
            return;
        }

        reviewsEmptyText.setVisibility(View.GONE);
        double totalRating = 0;
        int ratedCount = 0;
        for (Review review : reviews) {
            if (review.getRating() != null) {
                totalRating += review.getRating();
                ratedCount++;
            }
        }
        double average = ratedCount == 0 ? 0 : totalRating / ratedCount;
        reviewsSummaryText.setText(String.format(java.util.Locale.US, "★ %.1f  •  %d review%s",
                average,
                reviews.size(),
                reviews.size() == 1 ? "" : "s"));

        for (Review review : reviews) {
            reviewsContainer.addView(createReviewCard(review));
        }
    }

    private View createReviewCard(Review review) {
        LinearLayout card = new LinearLayout(this);
        card.setOrientation(LinearLayout.VERTICAL);
        card.setPadding(dp(14), dp(12), dp(14), dp(12));
        card.setBackgroundResource(R.drawable.bg_card);
        LinearLayout.LayoutParams cardParams = new LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
        );
        cardParams.setMargins(0, dp(10), 0, 0);
        card.setLayoutParams(cardParams);

        LinearLayout header = new LinearLayout(this);
        header.setOrientation(LinearLayout.HORIZONTAL);
        header.setGravity(Gravity.CENTER_VERTICAL);
        card.addView(header);

        TextView nameText = createText(value(review.getCustomerName(), "StyleOra Customer"), 15, R.color.text_primary, true);
        header.addView(nameText, new LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.WRAP_CONTENT, 1));

        TextView ratingText = createText(stars(review.getRating()), 14, R.color.primary, true);
        header.addView(ratingText);

        TextView commentText = createText(value(review.getReviewMessage(), "No comment provided."), 14, R.color.text_primary, false);
        commentText.setPadding(0, dp(8), 0, 0);
        commentText.setLineSpacing(dp(3), 1.0f);
        card.addView(commentText);

        TextView dateText = createText(value(review.getReviewDate(), value(review.getCreatedAt(), "")), 12, R.color.text_secondary, false);
        dateText.setPadding(0, dp(8), 0, 0);
        card.addView(dateText);
        return card;
    }

    private TextView createText(String text, int sp, int colorRes, boolean bold) {
        TextView textView = new TextView(this);
        textView.setText(text);
        textView.setTextSize(sp);
        textView.setTextColor(getColor(colorRes));
        if (bold) {
            textView.setTypeface(null, Typeface.BOLD);
        }
        return textView;
    }

    private String stars(Integer rating) {
        int value = rating == null ? 0 : Math.max(0, Math.min(5, rating));
        StringBuilder builder = new StringBuilder();
        for (int i = 1; i <= 5; i++) {
            builder.append(i <= value ? "★" : "☆");
        }
        return builder.toString();
    }

    private String buildMeta() {
        StringBuilder builder = new StringBuilder();
        append(builder, product.getBrand());
        append(builder, product.getCategory());
        append(builder, product.getSize());
        append(builder, product.getWeight());
        return builder.length() == 0 ? "Fashion essential" : builder.toString();
    }

    private void append(StringBuilder builder, String value) {
        if (value == null || value.trim().isEmpty()) {
            return;
        }
        if (builder.length() > 0) {
            builder.append(" / ");
        }
        builder.append(value.trim());
    }

    private BigDecimal getDiscountedPrice(BigDecimal price, BigDecimal discount) {
        BigDecimal safePrice = price == null ? BigDecimal.ZERO : price;
        BigDecimal safeDiscount = discount == null ? BigDecimal.ZERO : discount.max(BigDecimal.ZERO).min(BigDecimal.valueOf(100));
        return safePrice.multiply(BigDecimal.valueOf(100).subtract(safeDiscount))
                .divide(BigDecimal.valueOf(100), 2, RoundingMode.HALF_UP);
    }

    private String formatPrice(BigDecimal price) {
        return "$" + price.setScale(2, RoundingMode.HALF_UP).stripTrailingZeros().toPlainString();
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

    private List<String> buildGalleryImages() {
        List<String> gallery = new ArrayList<>();
        addImages(gallery, product.getImageUrls());
        addImages(gallery, product.getImages());
        addImages(gallery, product.getGalleryImages());
        addImage(gallery, product.getImageUrl());
        if (gallery.isEmpty()) {
            gallery.add(null);
        }
        return gallery;
    }

    private void addImages(List<String> gallery, List<String> imageUrls) {
        if (imageUrls == null) {
            return;
        }
        for (String imageUrl : imageUrls) {
            addImage(gallery, imageUrl);
        }
    }

    private void addImage(List<String> gallery, String imageUrl) {
        if (imageUrl == null || imageUrl.trim().isEmpty()) {
            return;
        }
        String[] parts = imageUrl.split(",");
        for (String part : parts) {
            String normalized = buildImageUrl(part);
            if (normalized != null && !gallery.contains(normalized)) {
                gallery.add(normalized);
            }
        }
    }

    private void createDots(int count, int selectedPosition) {
        dotsContainer.removeAllViews();
        if (count <= 1) {
            return;
        }
        for (int i = 0; i < count; i++) {
            TextView dot = new TextView(this);
            dot.setText(i == selectedPosition ? "●" : "○");
            dot.setTextSize(18);
            dot.setGravity(android.view.Gravity.CENTER);
            dot.setTextColor(getColor(i == selectedPosition ? R.color.primary : R.color.text_secondary));
            dotsContainer.addView(dot, new LinearLayout.LayoutParams(dp(22), dp(24)));
        }
    }

    private String value(String value, String fallback) {
        return value == null || value.trim().isEmpty() ? fallback : value;
    }

    private int dp(int value) {
        return (int) (value * getResources().getDisplayMetrics().density);
    }
}
