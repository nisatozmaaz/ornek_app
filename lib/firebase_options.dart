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
    apiKey: 'AIzaSyAAUl6NFebHkX5FHagsLqmzsShSSr2i1qM',
    appId: '1:373925576417:web:808003834df497e3b281a0',
    messagingSenderId: '373925576417',
    projectId: 'gidaprojem',
    authDomain: 'gidaprojem.firebaseapp.com',
    storageBucket: 'gidaprojem.firebasestorage.app',
    measurementId: 'G-BELDLJM71Y',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDX8b8oezy_-elcxYjlYXORX2tEAuihMu0',
    appId: '1:373925576417:android:407537ebde237f79b281a0',
    messagingSenderId: '373925576417',
    projectId: 'gidaprojem',
    storageBucket: 'gidaprojem.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDigR3UTrHcmnAw9A5-opjh8qgRghWJGYw',
    appId: '1:373925576417:ios:ba43a3b94aee6847b281a0',
    messagingSenderId: '373925576417',
    projectId: 'gidaprojem',
    storageBucket: 'gidaprojem.firebasestorage.app',
    iosBundleId: 'com.example.gidaIsrafi',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyDigR3UTrHcmnAw9A5-opjh8qgRghWJGYw',
    appId: '1:373925576417:ios:ba43a3b94aee6847b281a0',
    messagingSenderId: '373925576417',
    projectId: 'gidaprojem',
    storageBucket: 'gidaprojem.firebasestorage.app',
    iosBundleId: 'com.example.gidaIsrafi',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyAAUl6NFebHkX5FHagsLqmzsShSSr2i1qM',
    appId: '1:373925576417:web:f36441ccf8f9c313b281a0',
    messagingSenderId: '373925576417',
    projectId: 'gidaprojem',
    authDomain: 'gidaprojem.firebaseapp.com',
    storageBucket: 'gidaprojem.firebasestorage.app',
    measurementId: 'G-WRS63M3F0K',
  );
}
