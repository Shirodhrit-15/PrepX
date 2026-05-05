// ignore_for_file: unused_import, unused_field

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  User? _user;
  bool _isLoading = false;
  String? _error;

  // ✅ Getters
  User? get user => _user ?? _auth.currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;

  bool get isAuthenticated => _auth.currentUser != null;

  // ✅ FIXED UID
  String get uid => _auth.currentUser?.uid ?? '';

  AuthProvider() {
    _auth.authStateChanges().listen((user) {
      _user = user;
      notifyListeners();
    });
  }

  // ✅ SIGN IN
  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final cred = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      _user = cred.user;
      return true;
    } on FirebaseAuthException catch (e) {
      _error = e.message;
      return false;
    } catch (_) {
      _error = "Unexpected error";
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ✅ GOOGLE SIGN IN
  Future<bool> signInWithGoogle() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

      if (googleUser == null) {
        _error = "Google sign-in cancelled";
        return false;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);

      _user = userCredential.user;

      return true;
    } on FirebaseAuthException catch (e) {
      _error = e.message;
      return false;
    } catch (e) {
      _error = "Google sign-in failed";
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ✅ SIGN UP
  Future<bool> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final cred = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      await cred.user?.updateDisplayName(displayName);

      _user = cred.user;
      return true;
    } on FirebaseAuthException catch (e) {
      _error = e.message;
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ✅ 🔥 FIX YOUR ERROR HERE
  Future<bool> sendPasswordReset(String email) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _auth.sendPasswordResetEmail(email: email.trim());

      return true;
    } on FirebaseAuthException catch (e) {
      _error = e.message;
      return false;
    } catch (_) {
      _error = "Something went wrong";
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ✅ LOGOUT
  Future<void> signOut() async {
    await _auth.signOut();
    _user = null;
    notifyListeners();
  }
}
