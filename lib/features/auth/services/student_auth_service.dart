import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class StudentLoginResult {
  const StudentLoginResult({
    required this.user,
    required this.emailVerified,
    required this.accountStatus,
    required this.subscriptionStatus,
    required this.accessEnabled,
    required this.profile,
  });

  final User user;
  final bool emailVerified;
  final String accountStatus;
  final String subscriptionStatus;
  final bool accessEnabled;
  final Map<String, dynamic> profile;

  bool get isPendingApproval => accountStatus == 'pending';

  bool get isApproved => accountStatus == 'approved';

  bool get isRejected => accountStatus == 'rejected';

  // This is a UI convenience check, not a security boundary.
  bool get canEnterStudentArea => emailVerified;
}

class StudentAuthService {
  StudentAuthService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  User? get currentUser => _auth.currentUser;

  Future<StudentLoginResult> signIn({
    required String email,
    required String password,
  }) async {
    final cleanEmail = email.trim().toLowerCase();

    if (cleanEmail.isEmpty || password.isEmpty) {
      throw ArgumentError('Email and password are required.');
    }

    final credential = await _auth.signInWithEmailAndPassword(
      email: cleanEmail,
      password: password,
    );

    final user = credential.user;

    if (user == null) {
      await _auth.signOut();
      throw FirebaseAuthException(
        code: 'login-failed',
        message: 'Unable to sign in. Please try again.',
      );
    }

    await user.reload();

    final refreshedUser = _auth.currentUser;

    if (refreshedUser == null) {
      throw FirebaseAuthException(
        code: 'login-failed',
        message: 'Please sign in again.',
      );
    }

    final profileDocument = await _firestore
        .collection('users')
        .doc(refreshedUser.uid)
        .get();

    if (!profileDocument.exists) {
      await _auth.signOut();

      throw FirebaseAuthException(
        code: 'profile-not-found',
        message: 'Your student profile could not be found.',
      );
    }

    final profile = profileDocument.data() ?? {};

    return StudentLoginResult(
      user: refreshedUser,
      emailVerified: refreshedUser.emailVerified,
      accountStatus: profile['accountStatus'] as String? ?? 'pending',
      subscriptionStatus:
          profile['subscriptionStatus'] as String? ?? 'inactive',
      accessEnabled: profile['accessEnabled'] == true,
      profile: profile,
    );
  }

  Future<void> sendPasswordReset({
    required String email,
  }) async {
    final cleanEmail = email.trim().toLowerCase();

    if (cleanEmail.isEmpty) {
      throw ArgumentError('Please enter your email address.');
    }

    await _auth.sendPasswordResetEmail(
      email: cleanEmail,
    );
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
        message: 'Your email is already verified.',
      );
    }

    await refreshedUser.sendEmailVerification();
  }

  Future<bool> refreshEmailVerification() async {
    final user = _auth.currentUser;

    if (user == null) return false;

    await user.reload();

    return _auth.currentUser?.emailVerified ?? false;
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}
