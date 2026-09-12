package com.example.myshop;

import android.app.Activity;
import android.content.Intent;
import android.os.Bundle;
import android.util.Patterns;
import android.view.View;
import android.widget.Button;
import android.widget.EditText;
import android.widget.ProgressBar;
import android.widget.TextView;
import android.widget.Toast;

import com.example.myshop.model.AuthResponse;
import com.example.myshop.model.RegisterRequest;
import com.example.myshop.network.ApiErrorParser;
import com.example.myshop.network.RetrofitClient;
import com.example.myshop.storage.SessionManager;

import retrofit2.Call;
import retrofit2.Callback;
import retrofit2.Response;

public class RegisterActivity extends Activity {
    private EditText nameInput;
    private EditText emailInput;
    private EditText passwordInput;
    private EditText phoneInput;
    private EditText addressInput;
    private EditText cityInput;
    private EditText countryInput;
    private Button registerButton;
    private ProgressBar progressBar;
    private SessionManager sessionManager;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        ThemeManager.applyTheme(this);
        setContentView(R.layout.activity_register);

        sessionManager = new SessionManager(this);
        nameInput = findViewById(R.id.nameInput);
        emailInput = findViewById(R.id.emailInput);
        passwordInput = findViewById(R.id.passwordInput);
        phoneInput = findViewById(R.id.phoneInput);
        addressInput = findViewById(R.id.addressInput);
        cityInput = findViewById(R.id.cityInput);
        countryInput = findViewById(R.id.countryInput);
        registerButton = findViewById(R.id.registerButton);
        progressBar = findViewById(R.id.registerProgress);
        TextView loginLink = findViewById(R.id.loginLink);

        registerButton.setOnClickListener(view -> register());
        loginLink.setOnClickListener(view -> finish());
    }

    private void register() {
        String name = nameInput.getText().toString().trim();
        String email = emailInput.getText().toString().trim();
        String password = passwordInput.getText().toString();

        if (name.length() < 2) {
            nameInput.setError("Full name must be at least 2 characters.");
            nameInput.requestFocus();
            return;
        }

        if (!Patterns.EMAIL_ADDRESS.matcher(email).matches()) {
            emailInput.setError("Enter a valid email address.");
            emailInput.requestFocus();
            return;
        }

        if (password.length() < 6) {
            passwordInput.setError("Password must be at least 6 characters.");
            passwordInput.requestFocus();
            return;
        }

        RegisterRequest request = new RegisterRequest(
                name,
                email,
                password,
                phoneInput.getText().toString(),
                addressInput.getText().toString(),
                cityInput.getText().toString(),
                countryInput.getText().toString()
        );

        setLoading(true);
        RetrofitClient.getApiService().register(request).enqueue(new Callback<AuthResponse>() {
            @Override
            public void onResponse(Call<AuthResponse> call, Response<AuthResponse> response) {
                setLoading(false);
                AuthResponse body = response.body();

                if (response.isSuccessful() && body != null && body.isSuccess()
                        && hasText(body.getToken())) {
                    sessionManager.saveSession(body);
                    Toast.makeText(RegisterActivity.this, body.getMessage(), Toast.LENGTH_SHORT).show();
                    openHome();
                    return;
                }

                Toast.makeText(
                        RegisterActivity.this,
                        ApiErrorParser.getMessage(response),
                        Toast.LENGTH_LONG
                ).show();
            }

            @Override
            public void onFailure(Call<AuthResponse> call, Throwable throwable) {
                setLoading(false);
                Toast.makeText(
                        RegisterActivity.this,
                        "Cannot connect to the server. Check that the backend is running.",
                        Toast.LENGTH_LONG
                ).show();
            }
        });
    }

    private void setLoading(boolean loading) {
        registerButton.setEnabled(!loading);
        progressBar.setVisibility(loading ? View.VISIBLE : View.GONE);
    }

    private void openHome() {
        Intent intent = new Intent(this, HomeActivity.class);
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK | Intent.FLAG_ACTIVITY_CLEAR_TASK);
        startActivity(intent);
        finish();
    }

    private boolean hasText(String value) {
        return value != null && !value.trim().isEmpty();
    }
}
