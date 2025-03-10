// File generated by FlutterFire CLI.
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
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
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCam2I65pVchHPCKfq5iGZvrPzXK6YtUJ4',
    appId: '1:723708655722:web:6766907293f90b69c2f213',
    messagingSenderId: '723708655722',
    projectId: 'uber-health-app',
    authDomain: 'uber-health-app.firebaseapp.com',
    storageBucket: 'uber-health-app.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBJCDEbNNw-GuGFk0ZL1ZE-ynW9bV-3mFo',
    appId: '1:723708655722:android:36735f6d594ece86c2f213',
    messagingSenderId: '723708655722',
    projectId: 'uber-health-app',
    storageBucket: 'uber-health-app.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBueL0z2elc9NkDh-mv66PDhcWhZlTL3bo',
    appId: '1:723708655722:ios:da2b0cc2619d5b3cc2f213',
    messagingSenderId: '723708655722',
    projectId: 'uber-health-app',
    storageBucket: 'uber-health-app.firebasestorage.app',
    iosBundleId: 'com.example.uberHealthApp',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyBueL0z2elc9NkDh-mv66PDhcWhZlTL3bo',
    appId: '1:723708655722:ios:da2b0cc2619d5b3cc2f213',
    messagingSenderId: '723708655722',
    projectId: 'uber-health-app',
    storageBucket: 'uber-health-app.firebasestorage.app',
    iosBundleId: 'com.example.uberHealthApp',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyCam2I65pVchHPCKfq5iGZvrPzXK6YtUJ4',
    appId: '1:723708655722:web:45b3a80740196602c2f213',
    messagingSenderId: '723708655722',
    projectId: 'uber-health-app',
    authDomain: 'uber-health-app.firebaseapp.com',
    storageBucket: 'uber-health-app.firebasestorage.app',
  );
}
