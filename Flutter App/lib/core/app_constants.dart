import 'package:flutter/foundation.dart';

class AppConstants {
  AppConstants._();

  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:8080';
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'http://10.0.2.2:8080';
      default:
        return 'http://localhost:8080';
    }
  }

  static const String tokenKey = 'styleora_token';
  static const String roleKey = 'styleora_role';
  static const String customerKey = 'styleora_customer';
}
