package com.styleora.config;

import com.styleora.security.JwtAuthenticationFilter;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.HttpMethod;
import org.springframework.http.MediaType;
import org.springframework.security.config.annotation.web.configurers.AbstractHttpConfigurer;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter;
import org.springframework.web.cors.CorsUtils;

import java.util.LinkedHashMap;
import java.util.Map;

@Configuration
public class SecurityConfig {

    private final JwtAuthenticationFilter jwtAuthenticationFilter;
    public SecurityConfig(JwtAuthenticationFilter jwtAuthenticationFilter) {
        this.jwtAuthenticationFilter = jwtAuthenticationFilter;
    }

    @Bean
    public SecurityFilterChain filterChain(HttpSecurity http) throws Exception {
        http
                .cors(cors -> {})
                .csrf(AbstractHttpConfigurer::disable)
                .sessionManagement(session -> session.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
                .exceptionHandling(exception -> exception
                        .authenticationEntryPoint((request, response, authException) -> writeSecurityError(response, 401, "Authentication required."))
                        .accessDeniedHandler((request, response, accessDeniedException) -> writeSecurityError(response, 403, "You do not have permission to access this resource."))
                )
                .authorizeHttpRequests(auth -> auth
                        .requestMatchers(CorsUtils::isPreFlightRequest).permitAll()
                        .requestMatchers("/health").permitAll()
                        .requestMatchers(HttpMethod.POST, "/auth/login", "/customers/register", "/customers/login").permitAll()
                        .requestMatchers(HttpMethod.POST, "/products/*/reserve-stock", "/products/*/release-stock").permitAll()
                        .requestMatchers(
                                HttpMethod.GET,
                                "/uploads/**",
                                "/products/by-subcategory/*",
                                "/products/list",
                                "/products/*",
                                "/categories/list",
                                "/categories/*",
                                "/sub-categories/list",
                                "/sub-categories/*",
                                "/reviews/approved",
                                "/reviews/product/*/approved"
                        ).permitAll()
                        .requestMatchers(HttpMethod.POST, "/coupons/apply").hasRole("CUSTOMER")
                        .requestMatchers(HttpMethod.POST, "/reviews/submit").hasRole("CUSTOMER")
                        .requestMatchers(HttpMethod.POST, "/orders/create").hasAnyRole("ADMIN", "CUSTOMER", "SALES")
                        .requestMatchers(HttpMethod.POST, "/returns/request").hasRole("CUSTOMER")
                        .requestMatchers(HttpMethod.GET, "/reviews/my").hasRole("CUSTOMER")
                        .requestMatchers(HttpMethod.GET, "/reviews/my/order/**").hasRole("CUSTOMER")
                        .requestMatchers(HttpMethod.GET, "/returns/customer/**").hasAnyRole("ADMIN", "CUSTOMER")
                        .requestMatchers(HttpMethod.GET, "/shipments/order/**").hasAnyRole("ADMIN", "CUSTOMER", "MODERATOR", "SALES")
                        .requestMatchers("/orders/my/**", "/customers/profile/**").hasRole("CUSTOMER")
                        .requestMatchers(HttpMethod.GET, "/notifications/admin").hasAnyRole("ADMIN", "MODERATOR", "SALES")
                        .requestMatchers(HttpMethod.GET, "/products/low-stock").hasAnyRole("ADMIN", "MODERATOR", "SALES")
                        .requestMatchers(HttpMethod.GET, "/reports/**").hasAnyRole("ADMIN", "MODERATOR", "SALES")
                        .requestMatchers(HttpMethod.GET, "/customers/**").hasAnyRole("ADMIN", "MODERATOR", "SALES")
                        .requestMatchers(HttpMethod.GET, "/orders/**").hasAnyRole("ADMIN", "MODERATOR", "SALES")
                        .requestMatchers(HttpMethod.POST, "/orders/**").hasAnyRole("ADMIN", "SALES")
                        .requestMatchers(HttpMethod.PUT, "/orders/**").hasAnyRole("ADMIN", "SALES")
                        .requestMatchers(HttpMethod.GET, "/invoices/**").hasAnyRole("ADMIN", "SALES")
                        .requestMatchers(HttpMethod.POST, "/invoices/**").hasAnyRole("ADMIN", "SALES")
                        .requestMatchers(HttpMethod.PUT, "/invoices/**").hasAnyRole("ADMIN", "SALES")
                        .requestMatchers(HttpMethod.DELETE, "/invoices/**").hasAnyRole("ADMIN", "SALES")
                        .requestMatchers(HttpMethod.GET, "/payments/**").hasAnyRole("ADMIN", "SALES")
                        .requestMatchers(HttpMethod.POST, "/payments/**").hasAnyRole("ADMIN", "SALES")
                        .requestMatchers(HttpMethod.PUT, "/payments/**").hasAnyRole("ADMIN", "SALES")
                        .requestMatchers(HttpMethod.DELETE, "/payments/**").hasAnyRole("ADMIN", "SALES")
                        .requestMatchers(HttpMethod.GET, "/shipments/**").hasAnyRole("ADMIN", "SALES")
                        .requestMatchers(HttpMethod.POST, "/shipments/**").hasAnyRole("ADMIN", "SALES")
                        .requestMatchers(HttpMethod.PUT, "/shipments/**").hasAnyRole("ADMIN", "SALES")
                        .requestMatchers(HttpMethod.DELETE, "/shipments/**").hasAnyRole("ADMIN", "SALES")
                        .requestMatchers(HttpMethod.GET, "/shipping-methods/**").hasAnyRole("ADMIN", "SALES", "MODERATOR")
                        .requestMatchers(HttpMethod.POST, "/shipping-methods/**").hasAnyRole("ADMIN", "SALES")
                        .requestMatchers(HttpMethod.PUT, "/shipping-methods/**").hasAnyRole("ADMIN", "SALES")
                        .requestMatchers(HttpMethod.DELETE, "/shipping-methods/**").hasAnyRole("ADMIN", "SALES")
                        .requestMatchers("/reviews/**").hasAnyRole("ADMIN", "MODERATOR")
                        .requestMatchers("/returns/**").hasAnyRole("ADMIN", "MODERATOR")
                        .anyRequest().hasRole("ADMIN")
                )
                .addFilterBefore(jwtAuthenticationFilter, UsernamePasswordAuthenticationFilter.class);

        return http.build();
    }

    @Bean
    public PasswordEncoder passwordEncoder() {
        return new BCryptPasswordEncoder();
    }

    private void writeSecurityError(jakarta.servlet.http.HttpServletResponse response, int status, String message) throws java.io.IOException {
        response.setStatus(status);
        response.setContentType(MediaType.APPLICATION_JSON_VALUE);

        Map<String, Object> body = new LinkedHashMap<>();
        body.put("status", status);
        body.put("error", status == 401 ? "Unauthorized" : "Forbidden");
        body.put("message", message);
        body.put("timestamp", java.time.Instant.now().toString());

        response.getWriter().write("{"
                + "\"status\":" + status + ","
                + "\"error\":\"" + escapeJson(body.get("error").toString()) + "\","
                + "\"message\":\"" + escapeJson(message) + "\","
                + "\"timestamp\":\"" + escapeJson(body.get("timestamp").toString()) + "\""
                + "}");
    }

    private String escapeJson(String value) {
        return value.replace("\\", "\\\\").replace("\"", "\\\"");
    }
}
