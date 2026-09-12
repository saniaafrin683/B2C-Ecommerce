import 'package:flutter/foundation.dart';

import '../models/customer_profile.dart';
import '../models/session_data.dart';
import '../services/auth_service.dart';
import 'session_manager.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider({required this.authService, required this.sessionManager});

  final AuthService authService;
  final SessionManager sessionManager;

  bool _bootstrapped = false;
  bool _initializing = false;
  bool _submitting = false;
  String? _errorMessage;
  String? _token;
  String? _role;
  CustomerProfile? _customer;

  bool get isBootstrapped => _bootstrapped;
  bool get isInitializing => _initializing;
  bool get isSubmitting => _submitting;
  String? get errorMessage => _errorMessage;
  String? get token => _token;
  String? get role => _role;
  CustomerProfile? get customer => _customer;
  bool get isAuthenticated => _token != null && _token!.isNotEmpty;
  bool get isAdmin => _role?.trim().toUpperCase() == 'ADMIN';

  Future<void> bootstrap() async {
    if (_bootstrapped || _initializing) {
      return;
    }

    _setInitializing(true);
    try {
      final session = await sessionManager.loadSession();
      if (session != null) {
        _applySession(session);
      } else {
        _clearSessionState(notify: false);
      }
      _bootstrapped = true;
    } finally {
      _setInitializing(false);
    }
  }

  Future<void> login({required String email, required String password}) async {
    await _authenticate(
      () => authService.login(email: email, password: password),
    );
  }

  Future<void> register({
    required String fullName,
    required String email,
    required String password,
    String? phone,
    String? address,
    String? city,
    String? country,
  }) async {
    await _authenticate(
      () => authService.register(
        fullName: fullName,
        email: email,
        password: password,
        phone: phone,
        address: address,
        city: city,
        country: country,
      ),
    );
  }

  Future<void> logout() async {
    if (_submitting) {
      return;
    }

    _setSubmitting(true);
    try {
      await sessionManager.clearSession();
      _clearSessionState(notify: false);
    } finally {
      _setSubmitting(false);
    }
  }

  Future<void> _authenticate(Future<SessionData> Function() action) async {
    _setSubmitting(true);
    try {
      final session = await action();
      await sessionManager.saveSession(session);
      _applySession(session);
      _errorMessage = null;
    } catch (error) {
      _errorMessage = error.toString();
      rethrow;
    } finally {
      _setSubmitting(false);
    }
  }

  void _applySession(SessionData session) {
    _token = session.token;
    _role = session.role;
    _customer = session.customer;
    notifyListeners();
  }

  void _clearSessionState({bool notify = true}) {
    _token = null;
    _role = null;
    _customer = null;
    _errorMessage = null;
    if (notify) {
      notifyListeners();
    }
  }

  void _setInitializing(bool value) {
    _initializing = value;
    notifyListeners();
  }

  void _setSubmitting(bool value) {
    _submitting = value;
    notifyListeners();
  }
}
