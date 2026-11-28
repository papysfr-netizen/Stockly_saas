// Fichier à régénérer avec : `dart pub global activate flutterfire_cli && flutterfire configure`
// Les valeurs ci-dessous sont des espaces réservés : remplacez-les par celles
// de votre projet Firebase (Console Firebase > Paramètres du projet).
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        return ios;
      default:
        return web;
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'REMPLACER',
    appId: 'REMPLACER',
    messagingSenderId: 'REMPLACER',
    projectId: 'REMPLACER',
    authDomain: 'REMPLACER.firebaseapp.com',
    storageBucket: 'REMPLACER.appspot.com',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'REMPLACER',
    appId: 'REMPLACER',
    messagingSenderId: 'REMPLACER',
    projectId: 'REMPLACER',
    storageBucket: 'REMPLACER.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'REMPLACER',
    appId: 'REMPLACER',
    messagingSenderId: 'REMPLACER',
    projectId: 'REMPLACER',
    storageBucket: 'REMPLACER.appspot.com',
    iosBundleId: 'com.example.ecoleApp',
  );
}
