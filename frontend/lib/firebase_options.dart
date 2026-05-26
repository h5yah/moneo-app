import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'DefaultFirebaseOptions have not been configured for web - '
        'you can reconfigure this by running the FlutterFire CLI again.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
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

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBOv9RqeLXc6_O3OXalZmGsZkDZaNHD2gk',
    appId: '1:819485859824:android:daa4ae40d7e52c65638735',
    messagingSenderId: '819485859824',
    projectId: 'fyp-fintech-app',
    storageBucket: 'fyp-fintech-app.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBJbOFm284VKvazAXDigYzslMUv_RX9srg',
    appId: '1:819485859824:ios:7411fabc7c2d2739638735',
    messagingSenderId: '819485859824',
    projectId: 'fyp-fintech-app',
    storageBucket: 'fyp-fintech-app.firebasestorage.app',
    iosClientId: '819485859824-a7aok01h44pq3ef3a9l55h07i1f5ogto.apps.googleusercontent.com',
    iosBundleId: 'com.husniyah.fintech',
  );
}
