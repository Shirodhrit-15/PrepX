// auth_service.dart
// This file is structured for easy Firebase integration.
// Currently uses a mock/local approach. To connect real Firebase:
//   1. Run: flutter pub add firebase_core firebase_auth cloud_firestore
//   2. Follow FlutterFire CLI setup: flutterfire configure
//   3. Replace the mock logic below with real Firebase calls (marked with TODO)

// ignore_for_file: curly_braces_in_flow_control_structures

import 'package:flutter/foundation.dart';

class UserModel {
  final String uid;
  final String name;
  final String email;
  final String? profilePicPath;
  final String? resumePath;

  const UserModel({
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

  factory UserModel.fromMap(Map<String, dynamic> map) => UserModel(
        uid: map['uid'] ?? '',
        name: map['name'] ?? '',
        email: map['email'] ?? '',
        profilePicPath: map['profilePicPath'],
        resumePath: map['resumePath'],
      );
}

class AuthService extends ChangeNotifier {
  // Singleton
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  UserModel? _currentUser;
  bool _isLoading = false;
  String? _error;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _currentUser != null;
  String? get error => _error;

  // --------------------------------------------------------------------------
  // SIGN UP
  // --------------------------------------------------------------------------
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
      // Validation
      if (name.trim().isEmpty) throw Exception('Please enter your full name.');
      if (!_isValidEmail(email)) throw Exception('Please enter a valid email.');
      if (password.length < 6)
        throw Exception('Password must be at least 6 characters.');

      // TODO: Replace with Firebase Auth:
      // final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
      //   email: email, password: password);
      // await credential.user?.updateDisplayName(name);
      // await FirebaseFirestore.instance.collection('users').doc(credential.user!.uid).set({
      //   'name': name, 'email': email, 'createdAt': FieldValue.serverTimestamp(),
      // });

      // MOCK: Simulate network delay
      await Future.delayed(const Duration(seconds: 1));

      _currentUser = UserModel(
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

  // --------------------------------------------------------------------------
  // SIGN IN
  // --------------------------------------------------------------------------
  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    _error = null;

    try {
      if (!_isValidEmail(email)) throw Exception('Please enter a valid email.');
      if (password.isEmpty) throw Exception('Please enter your password.');

      // TODO: Replace with Firebase Auth:
      // final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
      //   email: email, password: password);
      // final doc = await FirebaseFirestore.instance
      //   .collection('users').doc(credential.user!.uid).get();
      // _currentUser = UserModel.fromMap(doc.data()!..addAll({'uid': credential.user!.uid}));

      // MOCK: Simulate network delay + fake check
      await Future.delayed(const Duration(milliseconds: 900));

      // For demo: any valid-looking credentials work
      _currentUser = UserModel(
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

  // --------------------------------------------------------------------------
  // SIGN OUT
  // --------------------------------------------------------------------------
  Future<void> signOut() async {
    // TODO: await FirebaseAuth.instance.signOut();
    _currentUser = null;
    _error = null;
    notifyListeners();
  }

  // --------------------------------------------------------------------------
  // HELPERS
  // --------------------------------------------------------------------------
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
