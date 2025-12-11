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
