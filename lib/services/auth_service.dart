// lib/services/auth_service.dart
// Legacy mock auth service kept for reference only.
// The app uses lib/providers/auth_provider.dart + lib/services/auth_service.dart.
// This file's class is renamed to MockAuthService to avoid any name collision.

// ignore_for_file: curly_braces_in_flow_control_structures

import 'package:flutter/foundation.dart';

class MockUserModel {
  final String uid;
  final String name;
  final String email;
  final String? profilePicPath;
  final String? resumePath;

  const MockUserModel({
    required this.uid,
    required this.name,
    required this.email,
    this.profilePicPath,
    this.resumePath,
  });

  Map<String, dynamic> toMap() => {
        'uid': uid,
        'name': name,
        'email': email,
        'profilePicPath': profilePicPath,
        'resumePath': resumePath,
      };

  factory MockUserModel.fromMap(Map<String, dynamic> map) => MockUserModel(
        uid: map['uid'] ?? '',
        name: map['name'] ?? '',
        email: map['email'] ?? '',
        profilePicPath: map['profilePicPath'],
        resumePath: map['resumePath'],
      );
}

/// Legacy mock auth provider — NOT used by the running app.
/// Kept only as a reference skeleton. The actual provider is
/// lib/providers/auth_provider.dart (class AuthProvider).
class MockAuthService extends ChangeNotifier {
  // Singleton
  static final MockAuthService _instance = MockAuthService._internal();
  factory MockAuthService() => _instance;
  MockAuthService._internal();

  MockUserModel? _currentUser;
  bool _isLoading = false;
  String? _error;

  MockUserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _currentUser != null;
  String? get error => _error;

  Future<bool> signUp({
    required String name,
    required String email,
    required String password,
    String? profilePicPath,
    String? resumePath,
  }) async {
    _setLoading(true);
    _error = null;
    try {
      if (name.trim().isEmpty) throw Exception('Please enter your full name.');
      if (!_isValidEmail(email)) throw Exception('Please enter a valid email.');
      if (password.length < 6)
        throw Exception('Password must be at least 6 characters.');

      await Future.delayed(const Duration(seconds: 1));

      _currentUser = MockUserModel(
        uid: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        email: email,
        profilePicPath: profilePicPath,
        resumePath: resumePath,
      );
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    _error = null;
    try {
      if (!_isValidEmail(email)) throw Exception('Please enter a valid email.');
      if (password.isEmpty) throw Exception('Please enter your password.');

      await Future.delayed(const Duration(milliseconds: 900));

      _currentUser = MockUserModel(
        uid: 'demo-uid-001',
        name: 'Demo User',
        email: email,
      );
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signOut() async {
    _currentUser = null;
    _error = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  void _setLoading(bool val) {
    _isLoading = val;
    notifyListeners();
  }
}
