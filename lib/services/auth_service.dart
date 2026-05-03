import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'firestore_service.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirestoreService _firestoreService = FirestoreService();

  // Stream of auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;
  String? get currentUserId => _auth.currentUser?.uid;

  // ─── Email / Password ────────────────────────────────────────────────────

  Future<UserCredential> signUpWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    // Update display name in Firebase Auth
    await credential.user?.updateDisplayName(displayName);

    // Create Firestore user document
    final user = UserModel(
      uid: credential.user!.uid,
      displayName: displayName,
      email: email,
      createdAt: DateTime.now(),
    );
    await _firestoreService.createUser(user);

    return credential;
  }

  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) async {
    return await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  // ─── Google Sign-In ───────────────────────────────────────────────────────

  Future<UserCredential?> signInWithGoogle() async {
    final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
    if (googleUser == null) return null; // user cancelled

    final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;

    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final userCredential = await _auth.signInWithCredential(credential);

    // Create Firestore doc if this is a new user
    if (userCredential.additionalUserInfo?.isNewUser ?? false) {
      final user = UserModel(
        uid: userCredential.user!.uid,
        displayName: userCredential.user!.displayName ?? 'User',
        email: userCredential.user!.email ?? '',
        photoUrl: userCredential.user!.photoURL,
        createdAt: DateTime.now(),
      );
      await _firestoreService.createUser(user);
    }

    return userCredential;
  }

  // ─── Password Reset ───────────────────────────────────────────────────────

  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  // ─── Sign Out ─────────────────────────────────────────────────────────────

  Future<void> signOut() async {
    await Future.wait([
      _auth.signOut(),
      _googleSignIn.signOut(),
    ]);
  }

  // ─── Delete Account ───────────────────────────────────────────────────────

  Future<void> deleteAccount() async {
    final uid = currentUserId;
    if (uid == null) return;
    await _firestoreService.deleteUser(uid);
    await _auth.currentUser?.delete();
  }
}
