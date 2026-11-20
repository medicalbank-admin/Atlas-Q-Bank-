import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;

      case TargetPlatform.iOS:
        return ios;

      default:
        throw UnsupportedError(
          'The Atlas Academy Firebase configuration '
          'is not supported on this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAP0bj6z-wf15cMaCkHFDa4_vynxL0H5HM',
    appId: '1:299084089644:web:f93b049f91507eb68f0489',
    messagingSenderId: '299084089644',
    projectId: 'the-atlas-academy-3fae0',
    authDomain: 'the-atlas-academy-3fae0.firebaseapp.com',
    storageBucket:
        'the-atlas-academy-3fae0.firebasestorage.app',
    measurementId: 'G-772L3XLBKQ',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDtoC3vxQmf1p6HCSbzy_dlAXDHM-UGAew',
    appId: '1:299084089644:android:c23f3d77d528dcda8f0489',
    messagingSenderId: '299084089644',
    projectId: 'the-atlas-academy-3fae0',
    storageBucket:
        'the-atlas-academy-3fae0.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBbi3zlGggsct92f0qVkURMPN8ZheMcnQQ',
    appId: '1:299084089644:ios:e8497f4a09e104268f0489',
    messagingSenderId: '299084089644',
    projectId: 'the-atlas-academy-3fae0',
    storageBucket:
        'the-atlas-academy-3fae0.firebasestorage.app',
    iosBundleId: 'com.atlasacademy.app',
  );
}
