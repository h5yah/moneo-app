import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // REGISTER
  Future<User?> registerUser(
      String firstName,
      String lastName,
      String email,
      String phone,
      String country,
      String password) async {
    try {
      // Create Firebase Auth user
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = result.user;

      if (user != null) {
        // Save extra data in Firestore
        await _firestore.collection('users').doc(user.uid).set({
          'firstName': firstName,
          'lastName': lastName,
          'email': email,
          'phone': phone,
          'country': country,
          'xp': 0, // Start XP at 0
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      return user;
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
      return result.user;
    } catch (e) {
      debugPrint('Login Error: $e');
      return null;
    }
  }

  // LOGOUT
  Future<void> logoutUser() async {
    await _auth.signOut();
  }

  // GET CURRENT USER
  User? get currentUser => _auth.currentUser;
}

