import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'flutter_passive_updater_platform_interface.dart';

/// An implementation of [FlutterPassiveUpdaterPlatform] that uses method channels.
class MethodChannelFlutterPassiveUpdater extends FlutterPassiveUpdaterPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('flutter_passive_updater');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
