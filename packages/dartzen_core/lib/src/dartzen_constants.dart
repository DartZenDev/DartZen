/// Environment constants
///
/// These constants are used to determine the current environment (DEV or PRD).
/// They are set via the environment variable DZ_ENV.
///
/// Usage:
/// ```dart
/// if (dzIsDev) {
///   // Development code
/// }
/// ```
const String dzEnv = String.fromEnvironment('DZ_ENV', defaultValue: 'prd');

/// Whether the current environment is development.
const bool dzIsDev = dzEnv == 'dev';

/// Whether the current environment is production.
const bool dzIsPrd = dzEnv == 'prd';

/// Whether the current environment is for testing.
const bool dzIsTest =
    String.fromEnvironment('DZ_IS_TEST', defaultValue: 'false') == 'true';

/// The name of the environment variable for the Google Cloud Project ID.
const String dzGcloudProjectEnvVar = 'GCLOUD_PROJECT';

/// The name of the environment variable for the Firestore Emulator host.
const String dzFirestoreEmulatorHostEnvVar = 'FIRESTORE_EMULATOR_HOST';

/// The name of the environment variable for the Firebase Storage Emulator host.
const String dzStorageEmulatorHostEnvVar = 'FIREBASE_STORAGE_EMULATOR_HOST';

/// The name of the environment variable for the Identity Toolkit Emulator host.
const String dzIdentityToolkitEmulatorHostEnvVar =
    'IDENTITY_TOOLKIT_EMULATOR_HOST';

/// Google Cloud Project ID from environment.
///
/// This is a compile-time constant that reads from the GCLOUD_PROJECT
/// environment variable. For tree-shaking to work properly, this must be
/// a compile-time constant, not a runtime value.
const String dzGcloudProject = String.fromEnvironment(dzGcloudProjectEnvVar);

/// Firestore Emulator host from environment.
///
/// This reads from FIRESTORE_EMULATOR_HOST at compile time.
/// Returns empty string if not set.
const String dzFirestoreEmulatorHost = String.fromEnvironment(
  dzFirestoreEmulatorHostEnvVar,
);

/// Firebase Storage Emulator host from environment.
///
/// This reads from FIREBASE_STORAGE_EMULATOR_HOST at compile time.
/// Returns empty string if not set.
const String dzStorageEmulatorHost = String.fromEnvironment(
  dzStorageEmulatorHostEnvVar,
);

/// Identity Toolkit Emulator host from environment.
///
/// This reads from IDENTITY_TOOLKIT_EMULATOR_HOST at compile time.
/// Returns empty string if not set.
const String dzIdentityToolkitEmulatorHost = String.fromEnvironment(
  dzIdentityToolkitEmulatorHostEnvVar,
);

/// Platform constants
///
/// These constants are used to determine the current platform.
/// They are set via the environment variable DZ_PLATFORM.
///
/// Usage:
/// ```dart
/// if (dzIsMobile) {
///   // Mobile code
/// }
/// ```
const String dzPlatform = String.fromEnvironment('DZ_PLATFORM');

/// Whether the current platform is Android.
const bool dzIsAndroid = dzPlatform == 'android';

/// Whether the current platform is iOS.
const bool dzIsIOS = dzPlatform == 'ios';

/// Whether the current platform is macOS.
const bool dzIsMacOS = dzPlatform == 'macos';

/// Whether the current platform is Linux.
const bool dzIsLinux = dzPlatform == 'linux';

/// Whether the current platform is Windows.
const bool dzIsWindows = dzPlatform == 'windows';

/// Whether the current platform is Web.
const bool dzIsWeb = dzPlatform == 'web';

/// Whether the current platform is mobile (Android or iOS).
const bool dzIsMobile = dzIsAndroid || dzIsIOS;

/// Whether the current platform is desktop (macOS, Linux, or Windows).
const bool dzIsDesktop = dzIsMacOS || dzIsLinux || dzIsWindows;

/// Maximum number of items to display in the mobile navigation bar.
const int dzMaxItemsMobile = 4;

/// Minimum width for the desktop navigation bar.
const int dzNarrowWidth = 720;
