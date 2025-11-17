// lib/env.dart
class Env {
  // Lidos em tempo de compilação via --dart-define
  static const flavor = String.fromEnvironment('FLAVOR', defaultValue: 'dev');

  static const useFirebaseEmulators = bool.fromEnvironment(
    'USE_FIREBASE_EMULATORS',
    defaultValue: false,
  );

  static bool get isDev => flavor == 'dev';
  static bool get isProd => flavor == 'prod';
}
