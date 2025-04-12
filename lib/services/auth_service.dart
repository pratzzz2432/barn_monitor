import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Stream of auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Email & Password Sign Up
  Future<User?> signUpWithEmail(String email, String password, String name) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = result.user;

      // Create user document in Firestore
      if (user != null) {
        await _firestore.collection('users').doc(user.uid).set({
          'name': name,
          'email': email,
          'createdAt': Timestamp.now(),
        });
      }

      return user;
    } catch (e) {
      print('Error signing up: ${e.toString()}');
      rethrow;
    }
  }

  // Email & Password Sign In
  Future<User?> signInWithEmail(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result.user;
    } catch (e) {
      print('Error signing in: ${e.toString()}');
      rethrow;
    }
  }

  // Send OTP for phone authentication
  Future<void> sendOTP(String phoneNumber, Function(PhoneAuthCredential) verificationCompleted,
      Function(FirebaseAuthException) verificationFailed,
      Function(String, int?) codeSent,
      Function(String) codeAutoRetrievalTimeout) async {

    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: verificationCompleted,
      verificationFailed: verificationFailed,
      codeSent: codeSent,
      codeAutoRetrievalTimeout: codeAutoRetrievalTimeout,
    );
  }

  // Verify OTP and sign in
  Future<User?> verifyOTP(String verificationId, String smsCode) async {
    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
          verificationId: verificationId,
          smsCode: smsCode
      );

      UserCredential result = await _auth.signInWithCredential(credential);

      User? user = result.user;

      // Create user document if it doesn't exist
      if (user != null) {
        final userDoc = await _firestore.collection('users').doc(user.uid).get();

        if (!userDoc.exists) {
          await _firestore.collection('users').doc(user.uid).set({
            'phoneNumber': user.phoneNumber,
            'createdAt': Timestamp.now(),
          });
        }
      }

      return user;
    } catch (e) {
      print('Error verifying OTP: ${e.toString()}');
      rethrow;
    }
  }

  // Sign Out
  Future<void> signOut() async {
    try {
      return await _auth.signOut();
    } catch (e) {
      print('Error signing out: ${e.toString()}');
      rethrow;
    }
  }
}