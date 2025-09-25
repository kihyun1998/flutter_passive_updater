import 'dart:io';

class FlutterPassiveUpdater {
  /// Starts an update by executing the Go updater binary
  /// The app will be terminated after calling this method
  static Future<void> startUpdate({
    required String updateZipPath,
    Future<void> Function()? onBeforeExit,
  }) async {
    try {
      // Get current app path
      final appPath = _getCurrentAppPath();

      // Create log path
      final logPath = '${Directory.systemTemp.path}/updater_${DateTime.now().millisecondsSinceEpoch}.log';

      // Get updater binary path for current platform
      final updaterPath = _getUpdaterBinaryPath();

      final result = await Process.run(updaterPath, [
        '-app', appPath,
        '-log', logPath,
      ]);

      if (result.exitCode == 0) {
        // Allow user to cleanup before exit
        if (onBeforeExit != null) {
          await onBeforeExit();
        }

        // Success - the updater should restart the app
        exit(0);
      } else {
        throw Exception('Updater failed with exit code: ${result.exitCode}');
      }
    } catch (e) {
      throw Exception('Error executing updater: $e');
    }
  }

  /// Gets the updater binary path for current platform
  static String _getUpdaterBinaryPath() {
    final executable = File(Platform.resolvedExecutable);

    if (Platform.isMacOS) {
      // Look for updater binary in app bundle Resources
      final appPath = _getCurrentAppPath();

      // Try Universal Binary first (app bundle)
      final bundleUniversal = '$appPath/Contents/Resources/updater-darwin-universal';
      if (File(bundleUniversal).existsSync()) {
        return bundleUniversal;
      }

      // Try Universal Binary in development path
      final devUniversal = '${executable.parent.parent.parent.path}/macos/Resources/updater-darwin-universal';
      if (File(devUniversal).existsSync()) {
        return devUniversal;
      }

      throw Exception('Universal binary not found. Please build it first:\n'
          'Run: dart run tool/build.dart');
    }

    throw Exception('Unsupported platform: ${Platform.operatingSystem}');
  }

  /// Gets the current app path
  static String _getCurrentAppPath() {
    if (Platform.isMacOS) {
      // On macOS, get the .app bundle path
      final executable = Platform.resolvedExecutable;
      // Navigate up from executable to .app bundle
      // e.g., /path/MyApp.app/Contents/MacOS/MyApp -> /path/MyApp.app
      final parts = executable.split('/');
      final appIndex = parts.lastIndexWhere((part) => part.endsWith('.app'));
      if (appIndex != -1) {
        return parts.take(appIndex + 1).join('/');
      }
    }

    // Fallback: return the directory containing the executable
    return File(Platform.resolvedExecutable).parent.path;
  }
}
