// ⚠️  DO NOT USE THIS FILE AS-IS.
// Run this command to auto-generate your real firebase_options.dart:
//
//   dart pub global activate flutterfire_cli
//   flutterfire configure --project=YOUR_FIREBASE_PROJECT_ID
//
// That command will replace this file with your actual keys.
// This template is here just to show the expected structure.

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
            'DefaultFirebaseOptions have not been configured for linux.');
      default:
        throw UnsupportedError(
            'DefaultFirebaseOptions are not supported for this platform.');
    }
  }

  // Replace all values below with those from your Firebase console
  // OR just run: flutterfire configure

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCmlr6S3ro4Ca3TPbs1xAMUTII7wwF9ECY',
    appId: '1:559813008501:web:002f2337cca065e90c2c3c',
    messagingSenderId: '559813008501',
    projectId: 'prepx-d58e0',
    authDomain: 'prepx-d58e0.firebaseapp.com',
    storageBucket: 'prepx-d58e0.firebasestorage.app',
    measurementId: 'G-68G9LT1RM0',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAdtFquXNY9DfEX3gATsvHMqoR7Vk8jtJQ',
    appId: '1:559813008501:android:22cf86584857715a0c2c3c',
    messagingSenderId: '559813008501',
    projectId: 'prepx-d58e0',
    storageBucket: 'prepx-d58e0.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDXJdD7sSx4OqIMYZKxKRYgEvRin4JGR3E',
    appId: '1:559813008501:ios:173bb30905b507310c2c3c',
    messagingSenderId: '559813008501',
    projectId: 'prepx-d58e0',
    storageBucket: 'prepx-d58e0.firebasestorage.app',
    iosClientId: '559813008501-pbofg1u2snl51pp0dskadcdl14f38ngc.apps.googleusercontent.com',
    iosBundleId: 'com.example.prepx',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyDXJdD7sSx4OqIMYZKxKRYgEvRin4JGR3E',
    appId: '1:559813008501:ios:173bb30905b507310c2c3c',
    messagingSenderId: '559813008501',
    projectId: 'prepx-d58e0',
    storageBucket: 'prepx-d58e0.firebasestorage.app',
    iosClientId: '559813008501-pbofg1u2snl51pp0dskadcdl14f38ngc.apps.googleusercontent.com',
    iosBundleId: 'com.example.prepx',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyDBNHUWMEoDBXpUr9PcwvcjPD0tWxEMqNI',
    appId: '1:559813008501:web:b08bc4f1615e1b430c2c3c',
    messagingSenderId: '559813008501',
    projectId: 'prepx-d58e0',
    authDomain: 'prepx-d58e0.firebaseapp.com',
    storageBucket: 'prepx-d58e0.firebasestorage.app',
    measurementId: 'G-0RNFJXXLED',
  );

}