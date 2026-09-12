package com.example.myshop;

import android.app.Activity;
import android.content.Intent;
import android.graphics.drawable.GradientDrawable;
import android.os.Bundle;
import android.os.Handler;
import android.os.Looper;
import android.view.View;
import android.view.inputmethod.EditorInfo;
import android.widget.EditText;
import android.widget.LinearLayout;
import android.widget.TextView;
import android.widget.Toast;

import androidx.recyclerview.widget.GridLayoutManager;
import androidx.recyclerview.widget.LinearLayoutManager;
import androidx.recyclerview.widget.RecyclerView;
import androidx.viewpager2.widget.ViewPager2;

import com.example.myshop.adapter.HomeBannerAdapter;
import com.example.myshop.adapter.HomeCategoryAdapter;
import com.example.myshop.adapter.HomeProductAdapter;
import com.example.myshop.model.Category;
import com.example.myshop.model.Product;
import com.example.myshop.network.RetrofitClient;
import com.example.myshop.storage.CartManager;
import com.example.myshop.storage.SessionManager;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collections;
import java.util.Comparator;
import java.util.List;

import retrofit2.Call;
import retrofit2.Callback;
import retrofit2.Response;

public class HomeActivity extends Activity {
    private final Handler sliderHandler = new Handler(Looper.getMainLooper());
    private ViewPager2 bannerPager;
    private LinearLayout dotsContainer;
    private TextView cartBadgeText;
    private EditText homeSearchInput;
    private HomeCategoryAdapter categoryAdapter;
    private HomeProductAdapter hotDealsAdapter;
    private HomeProductAdapter featuredAdapter;
    private HomeProductAdapter recommendedAdapter;
    private View hotDealsSkeleton;
    private View featuredSkeleton;
    private View hotDealsList;
    private View featuredList;

    private final Runnable sliderRunnable = new Runnable() {
        @Override
        public void run() {
            if (bannerPager != null && bannerPager.getAdapter() != null && bannerPager.getAdapter().getItemCount() > 0) {
                int nextItem = (bannerPager.getCurrentItem() + 1) % bannerPager.getAdapter().getItemCount();
                bannerPager.setCurrentItem(nextItem, true);
                sliderHandler.postDelayed(this, 3500);
            }
        }
    };

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        ThemeManager.applyTheme(this);
        SessionManager sessionManager = new SessionManager(this);
        if (!sessionManager.isLoggedIn()) {
            startActivity(new Intent(this, LoginActivity.class));
            finish();
            return;
        }

        setContentView(R.layout.activity_home);
        bindTopBar();
        setupBanner();
        setupSections();
        setupBottomNavigation();
        loadCategories();
        loadProducts();
    }

    @Override
    protected void onResume() {
        super.onResume();
        updateCartBadge();
        sliderHandler.postDelayed(sliderRunnable, 3500);
    }

    @Override
    protected void onPause() {
        super.onPause();
        sliderHandler.removeCallbacks(sliderRunnable);
    }

    private void bindTopBar() {
        cartBadgeText = findViewById(R.id.homeCartBadgeText);
        homeSearchInput = findViewById(R.id.homeSearchInput);
        findViewById(R.id.homeMenuButton).setOnClickListener(view -> scrollToTop());
        findViewById(R.id.homeSearchButton).setOnClickListener(view -> openSearch());
        findViewById(R.id.homeCartButton).setOnClickListener(view -> startActivity(new Intent(this, CartActivity.class)));
        findViewById(R.id.homeNotificationButton).setOnClickListener(view -> startActivity(new Intent(this, NotificationActivity.class)));
        findViewById(R.id.homeProfileButton).setOnClickListener(view -> startActivity(new Intent(this, ProfileActivity.class)));
        findViewById(R.id.homeWishlistShortcut).setOnClickListener(view -> startActivity(new Intent(this, WishlistActivity.class)));
        findViewById(R.id.homeOrdersShortcut).setOnClickListener(view -> startActivity(new Intent(this, OrdersActivity.class)));
        homeSearchInput.setOnEditorActionListener((view, actionId, event) -> {
            if (actionId == EditorInfo.IME_ACTION_SEARCH) {
                openSearch();
                return true;
            }
            return false;
        });
    }

    private void setupBanner() {
        bannerPager = findViewById(R.id.homeBannerPager);
        dotsContainer = findViewById(R.id.homeDotsContainer);
        List<String> titles = Arrays.asList(
                "Glow-ready fashion picks",
                "Hot deals just landed",
                "New arrivals for your wardrobe"
        );
        List<String> subtitles = Arrays.asList(
                "Curated beauty and fashion essentials for polished everyday looks.",
                "Limited-time prices on trending makeup, bags, outfits, and accessories.",
                "Fresh StyleOra pieces selected for your next wardrobe refresh."
        );
        bannerPager.setAdapter(new HomeBannerAdapter(titles, subtitles));
        createDots(titles.size(), 0);
        bannerPager.registerOnPageChangeCallback(new ViewPager2.OnPageChangeCallback() {
            @Override
            public void onPageSelected(int position) {
                createDots(titles.size(), position);
            }
        });
    }

    private void setupSections() {
        RecyclerView categoryRecyclerView = findViewById(R.id.homeCategoriesRecyclerView);
        RecyclerView hotDealsRecyclerView = findViewById(R.id.homeHotDealsRecyclerView);
        RecyclerView featuredRecyclerView = findViewById(R.id.homeFeaturedRecyclerView);
        RecyclerView recommendedRecyclerView = findViewById(R.id.homeRecommendedRecyclerView);
        hotDealsSkeleton = findViewById(R.id.homeHotDealsSkeleton);
        featuredSkeleton = findViewById(R.id.homeFeaturedSkeleton);
        hotDealsList = hotDealsRecyclerView;
        featuredList = featuredRecyclerView;

        categoryAdapter = new HomeCategoryAdapter(new ArrayList<>(), category -> {
            Intent intent = new Intent(this, ProductActivity.class);
            intent.putExtra(ProductActivity.EXTRA_TITLE, category.getDisplayName());
            intent.putExtra(ProductActivity.EXTRA_CATEGORY, category.getDisplayName());
            startActivity(intent);
        });
        categoryRecyclerView.setLayoutManager(new LinearLayoutManager(this, LinearLayoutManager.HORIZONTAL, false));
        categoryRecyclerView.setAdapter(categoryAdapter);

        HomeProductAdapter.OnProductClickListener productClickListener = product -> {
            Intent intent = new Intent(this, ProductDetailsActivity.class);
            intent.putExtra(ProductDetailsActivity.EXTRA_PRODUCT_ID, product.getId());
            startActivity(intent);
        };

        hotDealsAdapter = HomeProductAdapter.horizontal(new ArrayList<>(), productClickListener);
        hotDealsRecyclerView.setLayoutManager(new LinearLayoutManager(this, LinearLayoutManager.HORIZONTAL, false));
        hotDealsRecyclerView.setAdapter(hotDealsAdapter);

        featuredAdapter = HomeProductAdapter.grid(new ArrayList<>(), productClickListener);
        featuredRecyclerView.setLayoutManager(new GridLayoutManager(this, 2));
        featuredRecyclerView.setNestedScrollingEnabled(false);
        featuredRecyclerView.setAdapter(featuredAdapter);

        recommendedAdapter = HomeProductAdapter.horizontal(new ArrayList<>(), productClickListener);
        recommendedRecyclerView.setLayoutManager(new LinearLayoutManager(this, LinearLayoutManager.HORIZONTAL, false));
        recommendedRecyclerView.setAdapter(recommendedAdapter);

        findViewById(R.id.homeViewAllHotDeals).setOnClickListener(view -> {
            Intent intent = new Intent(this, ProductActivity.class);
            intent.putExtra(ProductActivity.EXTRA_TITLE, "Hot Deals");
            intent.putExtra(ProductActivity.EXTRA_HOT_DEALS, true);
            startActivity(intent);
        });
        findViewById(R.id.homeViewAllProducts).setOnClickListener(view -> startActivity(new Intent(this, ProductActivity.class)));
    }

    private void setupBottomNavigation() {
        findViewById(R.id.navHome).setOnClickListener(view -> scrollToTop());
        findViewById(R.id.navBrands).setOnClickListener(view -> {
            Intent intent = new Intent(this, ProductActivity.class);
            intent.putExtra(ProductActivity.EXTRA_TITLE, "Brands");
            startActivity(intent);
        });
        findViewById(R.id.navCategories).setOnClickListener(view -> startActivity(new Intent(this, CategoryActivity.class)));
        findViewById(R.id.navBlog).setOnClickListener(view -> startActivity(new Intent(this, BlogActivity.class)));
    }

    private void loadCategories() {
        RetrofitClient.getApiService().getCategories().enqueue(new Callback<List<Category>>() {
            @Override
            public void onResponse(Call<List<Category>> call, Response<List<Category>> response) {
                if (response.isSuccessful() && response.body() != null) {
                    categoryAdapter.setCategories(response.body());
                }
            }

            @Override
            public void onFailure(Call<List<Category>> call, Throwable throwable) {
                Toast.makeText(HomeActivity.this, "Categories unavailable.", Toast.LENGTH_SHORT).show();
            }
        });
    }

    private void loadProducts() {
        RetrofitClient.getApiService().getProducts().enqueue(new Callback<List<Product>>() {
            @Override
            public void onResponse(Call<List<Product>> call, Response<List<Product>> response) {
                if (!response.isSuccessful() || response.body() == null) {
                    Toast.makeText(HomeActivity.this, "Products unavailable.", Toast.LENGTH_SHORT).show();
                    return;
                }
                bindProducts(response.body());
            }

            @Override
            public void onFailure(Call<List<Product>> call, Throwable throwable) {
                Toast.makeText(HomeActivity.this, "Products unavailable.", Toast.LENGTH_SHORT).show();
            }
        });
    }

    private void bindProducts(List<Product> products) {
        List<Product> hotDeals = new ArrayList<>();
        for (Product product : products) {
            if (product.getDiscount() != null && product.getDiscount().signum() > 0) {
                hotDeals.add(product);
            }
        }
        hotDealsAdapter.setProducts(limit(hotDeals, 8));
        hotDealsSkeleton.setVisibility(View.GONE);
        hotDealsList.setVisibility(View.VISIBLE);

        List<Product> newest = new ArrayList<>(products);
        Collections.sort(newest, (left, right) -> {
            Long rightId = right.getId() == null ? 0L : right.getId();
            Long leftId = left.getId() == null ? 0L : left.getId();
            return rightId.compareTo(leftId);
        });
        featuredAdapter.setProducts(limit(newest, 6));
        featuredSkeleton.setVisibility(View.GONE);
        featuredList.setVisibility(View.VISIBLE);

        List<Product> recommended = new ArrayList<>(products);
        Collections.sort(recommended, Comparator.comparing(product -> product.getName() == null ? "" : product.getName()));
        recommendedAdapter.setProducts(limit(recommended, 8));
    }

    private List<Product> limit(List<Product> products, int limit) {
        return new ArrayList<>(products.subList(0, Math.min(limit, products.size())));
    }

    private void createDots(int count, int selectedPosition) {
        dotsContainer.removeAllViews();
        for (int i = 0; i < count; i++) {
            View dot = new View(this);
            GradientDrawable background = new GradientDrawable();
            background.setColor(getColor(i == selectedPosition ? R.color.primary : R.color.border));
            background.setCornerRadius(dp(4));
            dot.setBackground(background);
            LinearLayout.LayoutParams params = new LinearLayout.LayoutParams(
                    i == selectedPosition ? dp(22) : dp(8),
                    dp(8)
            );
            params.setMargins(dp(3), dp(8), dp(3), dp(8));
            dotsContainer.addView(dot, params);
        }
    }

    private void updateCartBadge() {
        int count = new CartManager(this).getCount();
        cartBadgeText.setVisibility(count > 0 ? View.VISIBLE : View.GONE);
        cartBadgeText.setText(String.valueOf(count));
    }

    private void openSearch() {
        Intent intent = new Intent(this, ProductActivity.class);
        String query = homeSearchInput.getText() == null ? "" : homeSearchInput.getText().toString().trim();
        if (!query.isEmpty()) {
            intent.putExtra(ProductActivity.EXTRA_TITLE, "Search");
            intent.putExtra(ProductActivity.EXTRA_SEARCH_QUERY, query);
        }
        startActivity(intent);
    }

    private void scrollToTop() {
        findViewById(R.id.homeRootScroll).scrollTo(0, 0);
    }

    private int dp(int value) {
        return (int) (value * getResources().getDisplayMetrics().density);
    }
}
