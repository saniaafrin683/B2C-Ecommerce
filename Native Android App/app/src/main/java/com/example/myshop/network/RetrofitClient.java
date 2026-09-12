package com.example.myshop.network;

import com.google.gson.Gson;
import com.google.gson.GsonBuilder;

import retrofit2.Retrofit;
import retrofit2.converter.gson.GsonConverterFactory;

public final class RetrofitClient {
    // Android Emulator uses 10.0.2.2 to reach localhost on the computer.
    private static final String BASE_URL = "http://10.0.2.2:8080/";
    private static final Gson GSON = new GsonBuilder().create();
    private static ApiService apiService;

    private RetrofitClient() {
    }

    public static synchronized ApiService getApiService() {
        if (apiService == null) {
            Retrofit retrofit = new Retrofit.Builder()
                    .baseUrl(BASE_URL)
                    .addConverterFactory(GsonConverterFactory.create(GSON))
                    .build();
            apiService = retrofit.create(ApiService.class);
        }
        return apiService;
    }

    public static Gson getGson() {
        return GSON;
    }

    public static String getBaseUrl() {
        return BASE_URL;
    }
}
