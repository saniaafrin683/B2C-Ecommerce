package com.example.myshop.network;

import com.example.myshop.model.AuthResponse;
import com.example.myshop.model.ApplyCouponRequest;
import com.example.myshop.model.ApplyCouponResponse;
import com.example.myshop.model.Category;
import com.example.myshop.model.Customer;
import com.example.myshop.model.LoginRequest;
import com.example.myshop.model.OrderDetails;
import com.example.myshop.model.OrderRequest;
import com.example.myshop.model.PaymentInitiateRequest;
import com.example.myshop.model.PaymentInitiateResponse;
import com.example.myshop.model.Product;
import com.example.myshop.model.ProductPageResponse;
import com.example.myshop.model.ProductStockAdjustmentRequest;
import com.example.myshop.model.ProductStockAdjustmentResponse;
import com.example.myshop.model.RegisterRequest;
import com.example.myshop.model.Review;
import com.example.myshop.model.ReviewSubmitRequest;
import com.example.myshop.model.ReturnRequest;
import com.example.myshop.model.ReturnRequestCreateRequest;
import com.example.myshop.model.SubCategory;

import java.util.List;

import okhttp3.ResponseBody;
import retrofit2.Call;
import retrofit2.http.Body;
import retrofit2.http.GET;
import retrofit2.http.Header;
import retrofit2.http.Path;
import retrofit2.http.POST;
import retrofit2.http.Query;
import retrofit2.http.Streaming;

public interface ApiService {

    @POST("customers/login")
    Call<AuthResponse> login(@Body LoginRequest request);

    @POST("customers/register")
    Call<AuthResponse> register(@Body RegisterRequest request);

    @GET("products/list")
    Call<List<Product>> getProducts();

    @GET("products/search")
    Call<ProductPageResponse> searchProducts(
            @Query("query") String query,
            @Query("category") String category,
            @Query("page") int page,
            @Query("size") int size,
            @Query("sortBy") String sortBy,
            @Query("sortDir") String sortDir
    );

    @GET("products/{id}")
    Call<Product> getProduct(@Path("id") long id);

    @GET("products/by-subcategory/{subCategoryId}")
    Call<List<Product>> getProductsBySubCategory(@Path("subCategoryId") long subCategoryId);

    @POST("products/{id}/reserve-stock")
    Call<ProductStockAdjustmentResponse> reserveStock(
            @Path("id") long id,
            @Body ProductStockAdjustmentRequest request
    );

    @GET("categories/list")
    Call<List<Category>> getCategories();

    @GET("subcategories/list")
    Call<List<SubCategory>> getSubCategories();

    @GET("subcategories/by-category/{categoryId}")
    Call<List<SubCategory>> getSubCategoriesByCategory(@Path("categoryId") long categoryId);

    @GET("customers/profile")
    Call<Customer> getProfile(@Header("Authorization") String authorization);

    @POST("orders/create")
    Call<OrderDetails> createOrder(
            @Header("Authorization") String authorization,
            @Body OrderRequest request
    );

    @GET("orders/my")
    Call<List<OrderDetails>> getMyOrders(@Header("Authorization") String authorization);

    @GET("orders/my/{id}")
    Call<OrderDetails> getMyOrderById(
            @Header("Authorization") String authorization,
            @Path("id") long id
    );

    @Streaming
    @GET("orders/my/{id}/invoice")
    Call<ResponseBody> downloadMyOrderInvoice(
            @Header("Authorization") String authorization,
            @Path("id") long id
    );

    @POST("payments/initiate")
    Call<PaymentInitiateResponse> initiatePayment(
            @Header("Authorization") String authorization,
            @Body PaymentInitiateRequest request
    );

    @GET("reviews/product/{productId}/approved")
    Call<List<Review>> getApprovedProductReviews(
            @Path("productId") long productId,
            @Query("limit") int limit
    );

    @POST("reviews/submit")
    Call<Review> submitReview(
            @Header("Authorization") String authorization,
            @Body ReviewSubmitRequest request
    );

    @POST("returns/request")
    Call<ReturnRequest> requestReturn(
            @Header("Authorization") String authorization,
            @Body ReturnRequestCreateRequest request
    );

    @GET("returns/customer/{customerId}")
    Call<List<ReturnRequest>> getCustomerReturnRequests(
            @Header("Authorization") String authorization,
            @Path("customerId") long customerId
    );

    @POST("coupons/apply")
    Call<ApplyCouponResponse> applyCoupon(@Body ApplyCouponRequest request);
}
