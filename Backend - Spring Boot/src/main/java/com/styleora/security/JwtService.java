package com.styleora.security;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import javax.crypto.Mac;
import javax.crypto.spec.SecretKeySpec;
import java.nio.charset.StandardCharsets;
import java.time.Instant;
import java.util.Base64;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

@Service
public class JwtService {

    private static final Base64.Encoder URL_ENCODER = Base64.getUrlEncoder().withoutPadding();
    private static final Base64.Decoder URL_DECODER = Base64.getUrlDecoder();

    private final byte[] signingKey;
    private final long expirationMs;

    public JwtService(
            @Value("${styleora.jwt.secret}") String secret,
            @Value("${styleora.jwt.expiration-ms}") long expirationMs
    ) {
        this.signingKey = secret.getBytes(StandardCharsets.UTF_8);
        this.expirationMs = expirationMs;
    }

    public String generateToken(Long id, String email, String role) {
        try {
            long issuedAt = Instant.now().getEpochSecond();
            long expiresAt = Instant.now().plusMillis(expirationMs).getEpochSecond();

            String headerJson = "{\"alg\":\"HS256\",\"typ\":\"JWT\"}";
            String payloadJson = "{"
                    + "\"sub\":\"" + escapeJson(email) + "\","
                    + "\"id\":" + (id == null ? "null" : id) + ","
                    + "\"role\":\"" + escapeJson(role) + "\","
                    + "\"iat\":" + issuedAt + ","
                    + "\"exp\":" + expiresAt
                    + "}";

            String encodedHeader = URL_ENCODER.encodeToString(headerJson.getBytes(StandardCharsets.UTF_8));
            String encodedPayload = URL_ENCODER.encodeToString(payloadJson.getBytes(StandardCharsets.UTF_8));
            String signature = sign(encodedHeader + "." + encodedPayload);

            return encodedHeader + "." + encodedPayload + "." + signature;
        } catch (Exception ex) {
            throw new IllegalStateException("Failed to generate token.", ex);
        }
    }

    public AuthenticatedUser extractUser(String token) {
        try {
            String[] parts = token.split("\\.");
            if (parts.length != 3) {
                throw new IllegalArgumentException("Invalid token format.");
            }

            String signingInput = parts[0] + "." + parts[1];
            String expectedSignature = sign(signingInput);
            if (!expectedSignature.equals(parts[2])) {
                throw new IllegalArgumentException("Invalid token signature.");
            }

            String payloadJson = new String(URL_DECODER.decode(parts[1]), StandardCharsets.UTF_8);
            Long exp = extractLong(payloadJson, "exp");
            if (exp == null || Instant.now().getEpochSecond() >= exp) {
                throw new IllegalArgumentException("Token expired.");
            }

            Long idValue = extractLong(payloadJson, "id");
            String email = extractString(payloadJson, "sub");
            String role = extractString(payloadJson, "role");

            return new AuthenticatedUser(idValue, email, role);
        } catch (Exception ex) {
            throw new IllegalArgumentException("Invalid token.", ex);
        }
    }

    private String sign(String value) throws Exception {
        Mac mac = Mac.getInstance("HmacSHA256");
        mac.init(new SecretKeySpec(signingKey, "HmacSHA256"));
        return URL_ENCODER.encodeToString(mac.doFinal(value.getBytes(StandardCharsets.UTF_8)));
    }

    private String extractString(String json, String key) {
        Matcher matcher = Pattern.compile("\"" + key + "\"\\s*:\\s*\"([^\"]*)\"").matcher(json);
        if (!matcher.find()) {
            return null;
        }
        return matcher.group(1);
    }

    private Long extractLong(String json, String key) {
        Matcher matcher = Pattern.compile("\"" + key + "\"\\s*:\\s*(null|\\d+)").matcher(json);
        if (!matcher.find()) {
            return null;
        }
        String value = matcher.group(1);
        return "null".equals(value) ? null : Long.parseLong(value);
    }

    private String escapeJson(String value) {
        return value == null ? "" : value.replace("\\", "\\\\").replace("\"", "\\\"");
    }
}
