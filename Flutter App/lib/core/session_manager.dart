import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/customer_profile.dart';
import '../models/session_data.dart';
import 'app_constants.dart';

class SessionManager {
  Future<SharedPreferences> _prefs() {
    return SharedPreferences.getInstance();
  }

  Future<SessionData?> loadSession() async {
    final prefs = await _prefs();
    final token = prefs.getString(AppConstants.tokenKey);
    final role = prefs.getString(AppConstants.roleKey);
    final customerJson = prefs.getString(AppConstants.customerKey);

    if (token == null ||
        token.isEmpty ||
        role == null ||
        role.isEmpty ||
        customerJson == null ||
        customerJson.isEmpty) {
      return null;
    }

    final dynamic decoded = jsonDecode(customerJson);
    if (decoded is! Map<String, dynamic>) {
      return null;
    }

    return SessionData(
      token: token,
      role: role,
      customer: CustomerProfile.fromJson(decoded),
    );
  }

  Future<void> saveSession(SessionData session) async {
    final prefs = await _prefs();
    await prefs.setString(AppConstants.tokenKey, session.token);
    await prefs.setString(AppConstants.roleKey, session.role);
    await prefs.setString(
      AppConstants.customerKey,
      jsonEncode(session.customer.toJson()),
    );
  }

  Future<void> clearSession() async {
    final prefs = await _prefs();
    await prefs.remove(AppConstants.tokenKey);
    await prefs.remove(AppConstants.roleKey);
    await prefs.remove(AppConstants.customerKey);
  }

  Future<bool> hasToken() async {
    final prefs = await _prefs();
    final token = prefs.getString(AppConstants.tokenKey);
    return token != null && token.isNotEmpty;
  }
}
