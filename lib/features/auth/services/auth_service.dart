
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class StudentRegistrationData {
  const StudentRegistrationData({
    required this.fullName,
    required this.fatherName,
    required this.nationalId,
    required this.whatsappNumber,
    required this.email,
    required this.password,
    required this.countryOfStudy,
    required this.university,
    required this.profileImageBytes,
    required this.profileImageFileName,
    required this.termsAccepted,
  });

  final String fullName;
  final String fatherName;
  final String nationalId;
  final String whatsappNumber;
  final String email;
  final String password;
  final String countryOfStudy;
  final String university;

  // Kept for the registration form.
  // Image uploading will be activated when Storage is available.
  final Uint8List profileImageBytes;
  final String profileImageFileName;

  final bool termsAccepted;
}

class AuthService {
  AuthService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  Future<UserCredential> registerStudent(
    StudentRegistrationData data,
  ) async {
    final email = data.email.trim().toLowerCase();

    if (data.fullName.trim().isEmpty ||
        data.fatherName.trim().isEmpty ||
        data.nationalId.trim().isEmpty ||
        data.whatsappNumber.trim().isEmpty ||
        email.isEmpty ||
        data.countryOfStudy.trim().isEmpty ||
        data.university.trim().isEmpty) {
      throw ArgumentError(
        'Please complete all required fields.',
      );
    }

    if (!data.termsAccepted) {
      throw ArgumentError(
        'You must accept the Terms and Conditions and Privacy Policy.',
      );
    }

    if (data.profileImageBytes.isEmpty) {
      throw ArgumentError(
        'Please select a profile picture.',
      );
    }

    if (data.password.length < 8) {
      throw ArgumentError(
        'Your password must contain at least 8 characters.',
      );
    }

    UserCredential? credential;

    try {
      // 1. Create the Firebase Authentication account.
      credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: data.password,
      );

      final user = credential.user;

      if (user == null) {
        throw FirebaseAuthException(
          code: 'account-creation-failed',
          message: 'Firebase could not create your account.',
        );
      }

      final uid = user.uid;

      // 2. Set the student's display name.
      await user.updateDisplayName(
        data.fullName.trim(),
      );

      // 3. Send email verification.
      await user.sendEmailVerification();

      // 4. Save the student profile in Firestore.
      // Profile image uploading is temporarily disabled.
      await _firestore.collection('users').doc(uid).set({
        'uid': uid,
        'fullName': data.fullName.trim(),
        'fatherName': data.fatherName.trim(),
        'nationalId': data.nationalId.trim(),
        'whatsappNumber': data.whatsappNumber.trim(),
        'email': email,
        'countryOfStudy': data.countryOfStudy.trim(),
        'university': data.university.trim(),

        'profileImageUrl': null,
        'profileImagePath': null,

        // New accounts always start with restricted access.
        'role': 'student',
        'accountStatus': 'pending',
        'subscriptionStatus': 'inactive',
        'accessEnabled': false,

        // Registration information.
        'emailVerified': false,
        'termsAccepted': true,

        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return credential;
    } catch (error) {
      // The profile is written only after verification email
      // dispatch succeeds. If profile creation fails, attempt
      // to remove the newly created Authentication account.
      final user = credential?.user;

      if (user != null) {
        try {
          await user.delete();
        } catch (_) {
          // Preserve the original error.
        }
      }

      rethrow;
    }
  }

  Future<bool> refreshEmailVerification() async {
    final user = _auth.currentUser;

    if (user == null) {
      return false;
    }

    await user.reload();

    final refreshedUser = _auth.currentUser;

    return refreshedUser?.emailVerified ?? false;
  }

  Future<void> resendVerificationEmail() async {
    final user = _auth.currentUser;

    if (user == null) {
      throw FirebaseAuthException(
        code: 'no-current-user',
        message: 'Please sign in first.',
      );
    }

    await user.reload();

    final refreshedUser = _auth.currentUser;

    if (refreshedUser == null) {
      throw FirebaseAuthException(
        code: 'no-current-user',
        message: 'Please sign in again.',
      );
    }

    if (refreshedUser.emailVerified) {
      throw FirebaseAuthException(
        code: 'email-already-verified',
        message: 'Your email address is already verified.',
      );
    }

    await refreshedUser.sendEmailVerification();
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}
