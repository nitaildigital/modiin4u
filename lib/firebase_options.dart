// A stand-in until the project's Firebase keys are added.
//
// `flutterfire configure --project=<the client's Firebase project>` replaces
// this file with the real one, under the same name and class. Until then
// every platform reports that it has no keys, and the push service
// (lib/core/push/push_service.dart) stays off rather than failing the app.

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform => throw UnsupportedError(
    'Firebase is not configured yet: run `flutterfire configure`.',
  );
}
