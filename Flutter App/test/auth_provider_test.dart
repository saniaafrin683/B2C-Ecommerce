import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:styleora_flutter/core/api_client.dart';
import 'package:styleora_flutter/core/app_constants.dart';
import 'package:styleora_flutter/core/auth_provider.dart';
import 'package:styleora_flutter/core/session_manager.dart';
import 'package:styleora_flutter/services/auth_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'logout removes the persisted session and clears authentication',
    () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        AppConstants.tokenKey: 'test-token',
        AppConstants.roleKey: 'CUSTOMER',
        AppConstants.customerKey:
            '{"id":1,"fullName":"Test User","email":"test@example.com"}',
      });

      final sessionManager = SessionManager();
      final provider = AuthProvider(
        authService: AuthService(apiClient: ApiClient()),
        sessionManager: sessionManager,
      );

      await provider.bootstrap();
      expect(provider.isAuthenticated, isTrue);

      await provider.logout();

      expect(provider.isAuthenticated, isFalse);
      expect(provider.token, isNull);
      expect(provider.role, isNull);
      expect(provider.customer, isNull);
      expect(provider.isSubmitting, isFalse);
      expect(await sessionManager.hasToken(), isFalse);
    },
  );
}
