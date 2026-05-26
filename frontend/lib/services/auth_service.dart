import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  
  Future<UserCredential?> signInWithGoogle() async {
    if (!GoogleSignIn.instance.supportsAuthenticate()) {
      throw UnsupportedError('Google Sign-In is not available on this platform.');
    }

    late final GoogleSignInAccount account;
    try {
      account = await GoogleSignIn.instance.authenticate(
        scopeHint: const <String>['email', 'profile'],
      );
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled ||
          e.code == GoogleSignInExceptionCode.interrupted) {
        return null;
      }
      rethrow;
    }

    final idToken = account.authentication.idToken;
    if (idToken == null) {
      throw StateError('Google Sign-In did not return an ID token.');
    }

    final oauthCredential = GoogleAuthProvider.credential(idToken: idToken);
    final result = await _auth.signInWithCredential(oauthCredential);
    final user = result.user;
    if (user == null) {
      throw StateError('Firebase sign-in returned no user.');
    }

    await _ensureGoogleUserFirestoreDoc(user);
    return result;
  }

  Future<void> _ensureGoogleUserFirestoreDoc(User user) async {
    await _ensureUserFirestoreDoc(user);
  }

  Future<void> _ensureUserFirestoreDoc(User user) async {
    final docRef = _firestore.collection('users').doc(user.uid);
    final snap = await docRef.get();
    if (snap.exists) return;

    final name = user.displayName?.trim() ?? '';
    final parts = name.split(RegExp(r'\s+'));
    final firstName = parts.isNotEmpty ? parts.first : '';
    final lastName = parts.length > 1 ? parts.sublist(1).join(' ') : '';

    await docRef.set({
      'firstName': firstName,
      'lastName': lastName,
      'email': user.email ?? '',
      'phone': '',
      'xp': 0,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // REGISTER
  Future<User?> registerUser(
      String firstName,
      String lastName,
      String email,
      String phone,
      String password) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = result.user;

      if (user != null) {
        await _firestore.collection('users').doc(user.uid).set({
          'firstName': firstName,
          'lastName': lastName,
          'email': email,
          'phone': phone,
          'xp': 0, 
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      return user;
    } on FirebaseAuthException {
      rethrow;
    } catch (e) {
      debugPrint('Registration Error: $e');
      return null;
    }
  }

  // LOGIN
  Future<User?> loginUser(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = result.user;
      if (user != null) {
        await _ensureUserFirestoreDoc(user);
      }
      return user;
    } catch (e) {
      debugPrint('Login Error: $e');
      return null;
    }
  }

  // LOGOUT
  Future<void> logoutUser() async {
    try {
      await GoogleSignIn.instance.signOut();
    } catch (e) {
      debugPrint('Google sign-out: $e');
    }
    await _auth.signOut();
  }

  User? get currentUser => _auth.currentUser;
}

