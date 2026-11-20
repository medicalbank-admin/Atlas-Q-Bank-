
import 'package:firebase_auth/firebase_auth.dart';

class AdminAccessService {
  AdminAccessService._();

  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Returns true only when the signed-in user has
  /// the trusted Firebase admin custom claim.
  static Future<bool> isAdmin({
    bool refreshToken = false,
  }) async {
    final user = _auth.currentUser;

    if (user == null) {
      return false;
    }

    try {
      final tokenResult = await user.getIdTokenResult(
        refreshToken,
      );

      return tokenResult.claims?['admin'] == true;
    } on FirebaseAuthException {
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Checks admin access and returns the current user UID.
  /// Returns null if the user is not an authenticated admin.
  static Future<String?> getAdminUid({
    bool refreshToken = false,
  }) async {
    final user = _auth.currentUser;

    if (user == null) {
      return null;
    }

    final allowed = await isAdmin(
      refreshToken: refreshToken,
    );

    return allowed ? user.uid : null;
  }

  /// Signs out the current account.
  static Future<void> signOut() async {
    await _auth.signOut();
  }
}
