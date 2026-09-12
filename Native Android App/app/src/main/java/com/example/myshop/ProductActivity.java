package com.example.myshop;

import android.app.Activity;
import android.content.Intent;
import android.os.Bundle;
import android.os.Handler;
import android.os.Looper;
import android.text.Editable;
import android.text.TextWatcher;
import android.view.View;
import android.widget.ArrayAdapter;
import android.widget.CheckBox;
import android.widget.EditText;
import android.widget.ProgressBar;
import android.widget.Spinner;
import android.widget.TextView;
import android.widget.Toast;
import android.widget.AdapterView;

import androidx.recyclerview.widget.GridLayoutManager;
import androidx.recyclerview.widget.RecyclerView;

import com.example.myshop.adapter.ProductAdapter;
import com.example.myshop.model.Product;
import com.example.myshop.model.ProductPageResponse;
import com.example.myshop.network.RetrofitClient;

import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.Collections;
import java.util.Comparator;
import java.util.List;

import retrofit2.Call;
import retrofit2.Callback;
import retrofit2.Response;

public class ProductActivity extends Activity {
    public static final String EXTRA_TITLE = "title";
    public static final String EXTRA_CATEGORY = "category";
    public static final String EXTRA_HOT_DEALS = "hot_deals";
    public static final String EXTRA_SEARCH_QUERY = "search_query";

    private ProductAdapter productAdapter;
    private ProgressBar progressBar;
    private TextView emptyText;
    private EditText searchInput;
    private EditText categoryInput;
    private CheckBox hotDealsCheckBox;
    private Spinner sortSpinner;
    private final List<Product> allProducts = new ArrayList<>();
    private final Handler searchHandler = new Handler(Looper.getMainLooper());
    private final Runnable backendSearchRunnable = this::loadProducts;
    private String categoryFilter;
    private String initialSearchQuery;
    private boolean hotDealsOnly;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        ThemeManager.applyTheme(this);
        setContentView(R.layout.activity_product);

        progressBar = findViewById(R.id.productsProgressBar);
        emptyText = findViewById(R.id.productsEmptyText);
        searchInput = findViewById(R.id.productSearchInput);
        categoryInput = findViewById(R.id.productCategoryInput);
        hotDealsCheckBox = findViewById(R.id.productHotDealsCheckBox);
        sortSpinner = findViewById(R.id.productSortSpinner);
        TextView titleText = findViewById(R.id.productsTitleText);
        RecyclerView productsRecyclerView = findViewById(R.id.productsRecyclerView);

        String title = getIntent().getStringExtra(EXTRA_TITLE);
        categoryFilter = getIntent().getStringExtra(EXTRA_CATEGORY);
        initialSearchQuery = getIntent().getStringExtra(EXTRA_SEARCH_QUERY);
        hotDealsOnly = getIntent().getBooleanExtra(EXTRA_HOT_DEALS, false);
        titleText.setText(title == null || title.trim().isEmpty() ? getString(R.string.products) : title);
        if (initialSearchQuery != null) {
            searchInput.setText(initialSearchQuery);
        }
        if (categoryFilter != null) {
            categoryInput.setText(categoryFilter);
        }
        hotDealsCheckBox.setChecked(hotDealsOnly);

        productAdapter = new ProductAdapter(new ArrayList<>(), product -> {
            Intent intent = new Intent(this, ProductDetailsActivity.class);
            intent.putExtra(ProductDetailsActivity.EXTRA_PRODUCT_ID, product.getId());
            startActivity(intent);
        });
        productsRecyclerView.setLayoutManager(new GridLayoutManager(this, 2));
        productsRecyclerView.setHasFixedSize(true);
        productsRecyclerView.setAdapter(productAdapter);
        setupSortAndFilterControls();

        findViewById(R.id.backButton).setOnClickListener(view -> finish());

        loadProducts();
    }

    private void loadProducts() {
        setLoading(true);
        RetrofitClient.getApiService().searchProducts(
                backendQuery(),
                backendCategory(),
                0,
                200,
                backendSortBy(),
                backendSortDir()
        ).enqueue(new Callback<ProductPageResponse>() {
            @Override
            public void onResponse(Call<ProductPageResponse> call, Response<ProductPageResponse> response) {
                setLoading(false);

                if (!response.isSuccessful() || response.body() == null) {
                    loadProductsFallback();
                    return;
                }

                allProducts.clear();
                allProducts.addAll(response.body().getContent());
                applyFiltersAndSort();
            }

            @Override
            public void onFailure(Call<ProductPageResponse> call, Throwable throwable) {
                loadProductsFallback();
            }
        });
    }

    private void loadProductsFallback() {
        RetrofitClient.getApiService().getProducts().enqueue(new Callback<List<Product>>() {
            @Override
            public void onResponse(Call<List<Product>> call, Response<List<Product>> response) {
                setLoading(false);
                if (!response.isSuccessful()) {
                    showError("Failed to load products.");
                    return;
                }
                allProducts.clear();
                allProducts.addAll(response.body() == null ? new ArrayList<>() : response.body());
                applyFiltersAndSort();
            }

            @Override
            public void onFailure(Call<List<Product>> call, Throwable throwable) {
                setLoading(false);
                showError("Cannot connect to product server.");
            }
        });
    }

    private void setLoading(boolean loading) {
        progressBar.setVisibility(loading ? View.VISIBLE : View.GONE);
        if (loading) {
            emptyText.setVisibility(View.GONE);
        }
    }

    private void showError(String message) {
        emptyText.setText(message);
        emptyText.setVisibility(View.VISIBLE);
        Toast.makeText(this, message, Toast.LENGTH_SHORT).show();
    }

    private void setupSortAndFilterControls() {
        ArrayAdapter<String> sortAdapter = new ArrayAdapter<>(
                this,
                R.layout.item_spinner_text,
                new String[]{"Newest", "Price low to high", "Price high to low"}
        );
        sortAdapter.setDropDownViewResource(R.layout.item_spinner_dropdown_text);
        sortSpinner.setAdapter(sortAdapter);

        TextWatcher watcher = new TextWatcher() {
            @Override
            public void beforeTextChanged(CharSequence s, int start, int count, int after) {
            }

            @Override
            public void onTextChanged(CharSequence s, int start, int before, int count) {
                scheduleBackendSearch();
            }

            @Override
            public void afterTextChanged(Editable s) {
            }
        };

        searchInput.addTextChangedListener(watcher);
        categoryInput.addTextChangedListener(watcher);
        hotDealsCheckBox.setOnCheckedChangeListener((buttonView, isChecked) -> applyFiltersAndSort());
        sortSpinner.setOnItemSelectedListener(new AdapterView.OnItemSelectedListener() {
            @Override
            public void onItemSelected(AdapterView<?> parent, View view, int position, long id) {
                scheduleBackendSearch();
            }

            @Override
            public void onNothingSelected(AdapterView<?> parent) {
            }
        });
    }

    private void scheduleBackendSearch() {
        searchHandler.removeCallbacks(backendSearchRunnable);
        searchHandler.postDelayed(backendSearchRunnable, 350);
    }

    private void applyFiltersAndSort() {
        if (productAdapter == null) {
            return;
        }
        List<Product> products = filterProducts(allProducts);
        sortProducts(products);
        productAdapter.setProducts(products);
        emptyText.setText("No products found.");
        emptyText.setVisibility(products.isEmpty() && progressBar.getVisibility() != View.VISIBLE ? View.VISIBLE : View.GONE);
    }

    private List<Product> filterProducts(List<Product> products) {
        List<Product> filtered = new ArrayList<>();
        String search = textOf(searchInput);
        String categorySearch = textOf(categoryInput);
        boolean onlyDeals = hotDealsCheckBox.isChecked();
        for (Product product : products) {
            if (onlyDeals && !hasDiscount(product)) {
                continue;
            }
            if (!categorySearch.isEmpty()) {
                if (!contains(product.getCategory(), categorySearch)
                        && !contains(product.getSubCategory(), categorySearch)) {
                    continue;
                }
            }
            if (!search.isEmpty() && !matchesSearch(product, search)) {
                continue;
            }
            filtered.add(product);
        }
        return filtered;
    }

    private void sortProducts(List<Product> products) {
        int selected = sortSpinner.getSelectedItemPosition();
        if (selected == 1) {
            Collections.sort(products, Comparator.comparing(this::currentPrice));
        } else if (selected == 2) {
            Collections.sort(products, (left, right) -> currentPrice(right).compareTo(currentPrice(left)));
        } else {
            Collections.sort(products, (left, right) -> {
                String rightDate = dateValue(right);
                String leftDate = dateValue(left);
                int dateCompare = rightDate.compareTo(leftDate);
                if (dateCompare != 0) {
                    return dateCompare;
                }
                Long rightId = right.getId() == null ? 0L : right.getId();
                Long leftId = left.getId() == null ? 0L : left.getId();
                return rightId.compareTo(leftId);
            });
        }
    }

    private boolean matchesSearch(Product product, String search) {
        return contains(product.getName(), search)
                || contains(product.getBrand(), search)
                || contains(product.getCategory(), search)
                || contains(product.getSubCategory(), search)
                || contains(product.getDescription(), search)
                || contains(product.getTag(), search)
                || contains(product.getGender(), search);
    }

    private boolean contains(String value, String search) {
        return value != null && value.toLowerCase().contains(search);
    }

    private boolean hasDiscount(Product product) {
        return product.getDiscount() != null && product.getDiscount().signum() > 0;
    }

    private BigDecimal currentPrice(Product product) {
        BigDecimal price = product.getPrice() == null ? BigDecimal.ZERO : product.getPrice();
        BigDecimal discount = product.getDiscount() == null ? BigDecimal.ZERO : product.getDiscount();
        if (discount.signum() <= 0) {
            return price;
        }
        BigDecimal safeDiscount = discount.max(BigDecimal.ZERO).min(BigDecimal.valueOf(100));
        return price.multiply(BigDecimal.valueOf(100).subtract(safeDiscount)).divide(BigDecimal.valueOf(100));
    }

    private String dateValue(Product product) {
        if (product.getCreatedAt() != null && !product.getCreatedAt().trim().isEmpty()) {
            return product.getCreatedAt().trim();
        }
        if (product.getUpdatedAt() != null && !product.getUpdatedAt().trim().isEmpty()) {
            return product.getUpdatedAt().trim();
        }
        return "";
    }

    private String textOf(EditText editText) {
        return editText.getText() == null ? "" : editText.getText().toString().trim().toLowerCase();
    }

    private String backendQuery() {
        String query = textOf(searchInput);
        return query.isEmpty() ? null : query;
    }

    private String backendCategory() {
        String category = textOf(categoryInput);
        return category.isEmpty() ? null : category;
    }

    private String backendSortBy() {
        int selected = sortSpinner.getSelectedItemPosition();
        if (selected == 1 || selected == 2) {
            return "price";
        }
        return "createdAt";
    }

    private String backendSortDir() {
        int selected = sortSpinner.getSelectedItemPosition();
        if (selected == 1) {
            return "asc";
        }
        return "desc";
    }
}
