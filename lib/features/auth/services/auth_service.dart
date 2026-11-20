import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

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
  final Uint8List profileImageBytes;
  final String profileImageFileName;
  final bool termsAccepted;
}

class AuthService {
  AuthService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

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
      throw ArgumentError('Please complete all required fields.');
    }

    if (!data.termsAccepted) {
      throw ArgumentError(
        'You must accept the Terms and Conditions and Privacy Policy.',
      );
    }

    if (data.profileImageBytes.isEmpty) {
      throw ArgumentError('Please select a profile picture.');
    }

    if (data.password.length < 8) {
      throw ArgumentError(
        'Your password must contain at least 8 characters.',
      );
    }

    UserCredential? credential;
    String? uploadedImagePath;
    DocumentReference<Map<String, dynamic>>? userDocument;

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
      await user.updateDisplayName(data.fullName.trim());

      // 3. Upload the profile picture.
      final extension = data.profileImageFileName
          .split('.')
          .last
          .toLowerCase();

      final contentType = switch (extension) {
        'png' => 'image/png',
        'webp' => 'image/webp',
        'gif' => 'image/gif',
        _ => 'image/jpeg',
      };

      uploadedImagePath = 'student_profiles/$uid/profile.$extension';

      final imageReference = _storage.ref().child(uploadedImagePath);

      await imageReference.putData(
        data.profileImageBytes,
        SettableMetadata(
          contentType: contentType,
          customMetadata: {
            'studentUid': uid,
          },
        ),
      );

      final profileImageUrl =
          await imageReference.getDownloadURL();

      // 4. Save the student's profile in Firestore.
      userDocument = _firestore.collection('users').doc(uid);

      await userDocument.set({
        'uid': uid,
        'fullName': data.fullName.trim(),
        'fatherName': data.fatherName.trim(),
        'nationalId': data.nationalId.trim(),
        'whatsappNumber': data.whatsappNumber.trim(),
        'email': email,
        'countryOfStudy': data.countryOfStudy.trim(),
        'university': data.university.trim(),
        'profileImageUrl': profileImageUrl,
        'profileImagePath': uploadedImagePath,

        // New accounts require administrator approval.
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

      // 5. Send email verification.
      await user.sendEmailVerification();

      return credential;
    } catch (error) {
      // Attempt to clean up partially created registration data.
      if (userDocument != null) {
        try {
          await userDocument.delete();
        } catch (_) {
          // Preserve the original registration error.
        }
      }

      if (uploadedImagePath != null) {
        try {
          await _storage.ref().child(uploadedImagePath).delete();
        } catch (_) {
          // The image may not have finished uploading.
        }
      }

      final user = credential?.user;

      if (user != null) {
        try {
          await user.delete();
        } catch (_) {
          // Preserve the original registration error.
        }
      }

      rethrow;
    }
  }

  // Refresh the current user's Firebase email verification status.
  Future<bool> refreshEmailVerification() async {
    final user = _auth.currentUser;

    if (user == null) {
      return false;
    }

    await user.reload();

    final refreshedUser = _auth.currentUser;

    return refreshedUser?.emailVerified ?? false;
  }

  // Send another verification email when required.
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

  // Sign out the current student.
  Future<void> signOut() async {
    await _auth.signOut();
  }
}
