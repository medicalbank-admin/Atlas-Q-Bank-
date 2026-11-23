
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';

import 'app/atlas_academy_app.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Production attestation for Android release builds; AI Logic rejects
  // requests without a valid App Check token when enforcement is enabled.
  try {
    await FirebaseAppCheck.instance.activate(
      androidProvider: kDebugMode ? AndroidProvider.debug : AndroidProvider.playIntegrity,
      appleProvider: kDebugMode ? AppleProvider.debug : AppleProvider.appAttest,
    );
  } catch (error) {
    // Keep the learning app usable if attestation initialization is unavailable.
    // AI requests will show an actionable App Check configuration message.
    debugPrint('Firebase App Check initialization failed: $error');
  }

  runApp(
    const ProviderScope(
      child: AtlasAcademyApp(),
    ),
  );
}
