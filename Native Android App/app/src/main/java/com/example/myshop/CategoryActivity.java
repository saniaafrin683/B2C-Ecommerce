package com.example.myshop;

import android.app.Activity;
import android.content.Intent;
import android.os.Bundle;
import android.text.Editable;
import android.text.TextWatcher;
import android.view.View;
import android.view.inputmethod.EditorInfo;
import android.widget.EditText;
import android.widget.ProgressBar;
import android.widget.TextView;
import android.widget.Toast;

import androidx.recyclerview.widget.GridLayoutManager;
import androidx.recyclerview.widget.RecyclerView;

import com.example.myshop.adapter.CategoryAdapter;
import com.example.myshop.model.Category;
import com.example.myshop.model.SubCategory;
import com.example.myshop.network.RetrofitClient;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

import retrofit2.Call;
import retrofit2.Callback;
import retrofit2.Response;

public class CategoryActivity extends Activity {
    private RecyclerView categoryRecyclerView;
    private ProgressBar progressBar;
    private TextView emptyText;
    private EditText searchInput;
    private CategoryAdapter categoryAdapter;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        ThemeManager.applyTheme(this);
        setContentView(R.layout.activity_category);

        findViewById(R.id.backButton).setOnClickListener(view -> finish());
        categoryRecyclerView = findViewById(R.id.categoryRecyclerView);
        progressBar = findViewById(R.id.categoryProgressBar);
        emptyText = findViewById(R.id.categoryEmptyText);
        searchInput = findViewById(R.id.categorySearchInput);
        GridLayoutManager layoutManager = new GridLayoutManager(this, 2);
        layoutManager.setSpanSizeLookup(new GridLayoutManager.SpanSizeLookup() {
            @Override
            public int getSpanSize(int position) {
                return categoryAdapter != null && categoryAdapter.isHeader(position) ? 2 : 1;
            }
        });
        categoryRecyclerView.setLayoutManager(layoutManager);
        setupBottomNavigation();
        bindSearch();
        loadCategories();
    }

    private void bindSearch() {
        searchInput.setOnEditorActionListener((view, actionId, event) -> actionId == EditorInfo.IME_ACTION_SEARCH);
        searchInput.addTextChangedListener(new TextWatcher() {
            @Override
            public void beforeTextChanged(CharSequence sequence, int start, int count, int after) {
            }

            @Override
            public void onTextChanged(CharSequence sequence, int start, int before, int count) {
                if (categoryAdapter != null) {
                    categoryAdapter.filter(sequence == null ? "" : sequence.toString());
                    updateEmptyState();
                }
            }

            @Override
            public void afterTextChanged(Editable editable) {
            }
        });
    }

    private void loadCategories() {
        progressBar.setVisibility(View.VISIBLE);
        RetrofitClient.getApiService().getCategories().enqueue(new Callback<List<Category>>() {
            @Override
            public void onResponse(Call<List<Category>> call, Response<List<Category>> response) {
                progressBar.setVisibility(View.GONE);
                if (!response.isSuccessful() || response.body() == null || response.body().isEmpty()) {
                    emptyText.setVisibility(View.VISIBLE);
                    return;
                }
                bindCategories(response.body());
            }

            @Override
            public void onFailure(Call<List<Category>> call, Throwable throwable) {
                progressBar.setVisibility(View.GONE);
                emptyText.setVisibility(View.VISIBLE);
                Toast.makeText(CategoryActivity.this, "Unable to load categories.", Toast.LENGTH_SHORT).show();
            }
        });
    }

    private void bindCategories(List<Category> categories) {
        categoryAdapter = new CategoryAdapter(categories, this::openCategory);
        categoryRecyclerView.setAdapter(categoryAdapter);
        categoryRecyclerView.setVisibility(View.VISIBLE);
        emptyText.setVisibility(View.GONE);
        loadSubCategoryCounts();
    }

    private void loadSubCategoryCounts() {
        RetrofitClient.getApiService().getSubCategories().enqueue(new Callback<List<SubCategory>>() {
            @Override
            public void onResponse(Call<List<SubCategory>> call, Response<List<SubCategory>> response) {
                if (!response.isSuccessful() || response.body() == null || categoryAdapter == null) {
                    return;
                }
                categoryAdapter.setSubCategoryCounts(countByCategory(response.body()));
            }

            @Override
            public void onFailure(Call<List<SubCategory>> call, Throwable throwable) {
            }
        });
    }

    private Map<Long, Integer> countByCategory(List<SubCategory> subCategories) {
        Map<Long, Integer> counts = new HashMap<>();
        for (SubCategory subCategory : subCategories) {
            Long categoryId = subCategory.getCategoryId();
            if (categoryId != null) {
                Integer current = counts.get(categoryId);
                counts.put(categoryId, current == null ? 1 : current + 1);
            }
        }
        return counts;
    }

    private void openCategory(Category category) {
        Intent intent = new Intent(this, ProductActivity.class);
        intent.putExtra(ProductActivity.EXTRA_TITLE, category.getDisplayName());
        intent.putExtra(ProductActivity.EXTRA_CATEGORY, category.getDisplayName());
        startActivity(intent);
    }

    private void setupBottomNavigation() {
        findViewById(R.id.navHome).setOnClickListener(view -> startActivity(new Intent(this, HomeActivity.class)));
        findViewById(R.id.navBrands).setOnClickListener(view -> {
            Intent intent = new Intent(this, ProductActivity.class);
            intent.putExtra(ProductActivity.EXTRA_TITLE, "Brands");
            startActivity(intent);
        });
        findViewById(R.id.navCategories).setOnClickListener(view -> categoryRecyclerView.scrollToPosition(0));
        findViewById(R.id.navBlog).setOnClickListener(view -> startActivity(new Intent(this, BlogActivity.class)));
    }

    private void updateEmptyState() {
        boolean isEmpty = categoryAdapter == null || categoryAdapter.getVisibleCategoryCount() == 0;
        emptyText.setText(isEmpty ? "No matching categories found." : "No categories found.");
        emptyText.setVisibility(isEmpty ? View.VISIBLE : View.GONE);
        categoryRecyclerView.setVisibility(isEmpty ? View.GONE : View.VISIBLE);
    }
}
