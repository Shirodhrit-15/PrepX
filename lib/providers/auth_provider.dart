import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../models/user_model.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();

  AuthStatus _status = AuthStatus.unknown;
  UserModel? _userModel;
  String? _error;
  bool _isLoading = false;

  AuthStatus get status => _status;
  UserModel? get userModel => _userModel;
  String? get error => _error;
  bool get isLoading => _isLoading;
  String? get uid => _authService.currentUserId;
  bool get isAuthenticated => _status == AuthStatus.authenticated;

  AuthProvider() {
    _authService.authStateChanges.listen(_onAuthStateChanged);
  }

  void _onAuthStateChanged(User? user) async {
    if (user == null) {
      _status = AuthStatus.unauthenticated;
      _userModel = null;
    } else {
      _status = AuthStatus.authenticated;
      _userModel = await _firestoreService.getUser(user.uid);
    }
    notifyListeners();
  }

  // ─── Sign Up ──────────────────────────────────────────────────────────────

  Future<bool> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    _setLoading(true);
    try {
      await _authService.signUpWithEmail(
        email: email,
        password: password,
        displayName: displayName,
      );
      _clearError();
      return true;
    } on FirebaseAuthException catch (e) {
      _setError(_friendlyAuthError(e.code));
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ─── Sign In ──────────────────────────────────────────────────────────────

  Future<bool> signIn({required String email, required String password}) async {
    _setLoading(true);
    try {
      await _authService.signInWithEmail(email: email, password: password);
      _clearError();
      return true;
    } on FirebaseAuthException catch (e) {
      _setError(_friendlyAuthError(e.code));
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ─── Google Sign-In ───────────────────────────────────────────────────────

  Future<bool> signInWithGoogle() async {
    _setLoading(true);
    try {
      final result = await _authService.signInWithGoogle();
      _clearError();
      return result != null;
    } on FirebaseAuthException catch (e) {
      _setError(_friendlyAuthError(e.code));
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ─── Password Reset ───────────────────────────────────────────────────────

  Future<bool> sendPasswordReset(String email) async {
    _setLoading(true);
    try {
      await _authService.sendPasswordResetEmail(email);
      _clearError();
      return true;
    } on FirebaseAuthException catch (e) {
      _setError(_friendlyAuthError(e.code));
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ─── Sign Out ─────────────────────────────────────────────────────────────

  Future<void> signOut() async {
    await _authService.signOut();
  }

  // ─── Profile Update ───────────────────────────────────────────────────────

  Future<void> refreshUserModel() async {
    if (uid == null) return;
    _userModel = await _firestoreService.getUser(uid!);
    notifyListeners();
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  void _setLoading(bool v) {
    _isLoading = v;
    notifyListeners();
  }

  void _setError(String msg) {
    _error = msg;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
  }

  String _friendlyAuthError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'weak-password':
        return 'Password must be at least 6 characters.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait and try again.';
      case 'network-request-failed':
        return 'Network error. Check your connection.';
      default:
        return 'Something went wrong. Please try again.';
    }
  }
}
