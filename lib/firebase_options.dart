import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

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
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
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
    apiKey: 'AIzaSyD5tBmpIcVeoHv7tavYNyyG2e2zYOJhTz0',
    appId: '1:56093910685:web:3dc356b971bcebee9ad674',
    messagingSenderId: '56093910685',
    projectId: 'play-2-earn-68838',
    authDomain: 'play-2-earn-68838.firebaseapp.com',
    storageBucket: 'play-2-earn-68838.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyD5tBmpIcVeoHv7tavYNyyG2e2zYOJhTz0',
    appId: '1:56093910685:android:3dc356b971bcebee9ad674',
    messagingSenderId: '56093910685',
    projectId: 'play-2-earn-68838',
    storageBucket: 'play-2-earn-68838.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyD5tBmpIcVeoHv7tavYNyyG2e2zYOJhTz0',
    appId: '1:56093910685:ios:3dc356b971bcebee9ad674',
    messagingSenderId: '56093910685',
    projectId: 'play-2-earn-68838',
    storageBucket: 'play-2-earn-68838.firebasestorage.app',
    iosClientId:
        '56093910685-5jnq4sipqvh3qtbpqkpc6edotp7bau1e.apps.googleusercontent.com',
    iosBundleId: 'com.example.play_2_earn',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyD5tBmpIcVeoHv7tavYNyyG2e2zYOJhTz0',
    appId: '1:56093910685:macos:3dc356b971bcebee9ad674',
    messagingSenderId: '56093910685',
    projectId: 'play-2-earn-68838',
    storageBucket: 'play-2-earn-68838.firebasestorage.app',
    iosClientId:
        '56093910685-5jnq4sipqvh3qtbpqkpc6edotp7bau1e.apps.googleusercontent.com',
    iosBundleId: 'com.example.play_2_earn',
  );
}
