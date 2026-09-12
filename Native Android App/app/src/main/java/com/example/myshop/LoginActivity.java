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
import com.example.myshop.model.LoginRequest;
import com.example.myshop.network.ApiErrorParser;
import com.example.myshop.network.RetrofitClient;
import com.example.myshop.storage.SessionManager;

import retrofit2.Call;
import retrofit2.Callback;
import retrofit2.Response;

public class LoginActivity extends Activity {
    private EditText emailInput;
    private EditText passwordInput;
    private Button loginButton;
    private ProgressBar progressBar;
    private SessionManager sessionManager;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        ThemeManager.applyTheme(this);

        sessionManager = new SessionManager(this);
        setContentView(R.layout.activity_login);
        emailInput = findViewById(R.id.emailInput);
        passwordInput = findViewById(R.id.passwordInput);
        loginButton = findViewById(R.id.loginButton);
        progressBar = findViewById(R.id.loginProgress);
        TextView registerLink = findViewById(R.id.registerLink);

        loginButton.setOnClickListener(view -> login());
        registerLink.setOnClickListener(view ->
                startActivity(new Intent(LoginActivity.this, RegisterActivity.class)));
    }

    private void login() {
        String email = emailInput.getText().toString().trim();
        String password = passwordInput.getText().toString();

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

        setLoading(true);
        RetrofitClient.getApiService()
                .login(new LoginRequest(email, password))
                .enqueue(new Callback<AuthResponse>() {
                    @Override
                    public void onResponse(Call<AuthResponse> call, Response<AuthResponse> response) {
                        setLoading(false);
                        AuthResponse body = response.body();

                        if (response.isSuccessful() && body != null && body.isSuccess()
                                && hasText(body.getToken())) {
                            sessionManager.saveSession(body);
                            Toast.makeText(LoginActivity.this, body.getMessage(), Toast.LENGTH_SHORT).show();
                            openHome();
                            return;
                        }

                        Toast.makeText(
                                LoginActivity.this,
                                ApiErrorParser.getMessage(response),
                                Toast.LENGTH_LONG
                        ).show();
                    }

                    @Override
                    public void onFailure(Call<AuthResponse> call, Throwable throwable) {
                        setLoading(false);
                        Toast.makeText(
                                LoginActivity.this,
                                "Cannot connect to the server. Check that the backend is running.",
                                Toast.LENGTH_LONG
                        ).show();
                    }
                });
    }

    private void setLoading(boolean loading) {
        loginButton.setEnabled(!loading);
        progressBar.setVisibility(loading ? View.VISIBLE : View.GONE);
    }

    private void openHome() {
        Intent intent = new Intent(this, HomeActivity.class);
        startActivity(intent);
        finish();
    }

    private boolean hasText(String value) {
        return value != null && !value.trim().isEmpty();
    }
}
