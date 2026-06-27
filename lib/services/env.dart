// lib/env.dart
class Env {
  // Lidos em tempo de compilação via --dart-define
  static const flavor = String.fromEnvironment('FLAVOR', defaultValue: 'dev');
  static const adminMode = String.fromEnvironment(
    'ADMIN_MODE',
    defaultValue: '',
  );
  static const adminUsername = String.fromEnvironment(
    'ADMIN_USERNAME',
    defaultValue: 'admin',
  );
  static const adminPassword = String.fromEnvironment(
    'ADMIN_PASSWORD',
    defaultValue: 'admin',
  );

  static const useFirebaseEmulators = bool.fromEnvironment(
    'USE_FIREBASE_EMULATORS',
    defaultValue: false,
  );
  static const buildNumber = String.fromEnvironment(
    'BUILD_NUMBER',
    defaultValue: 'local',
  );
  static const gitSha = String.fromEnvironment(
    'GIT_SHA',
    defaultValue: 'unknown',
  );

  static bool get isDev => flavor == 'dev';
  static bool get isProd => flavor == 'prod';
}
