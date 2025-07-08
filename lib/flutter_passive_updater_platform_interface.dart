import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'flutter_passive_updater_method_channel.dart';

abstract class FlutterPassiveUpdaterPlatform extends PlatformInterface {
  /// Constructs a FlutterPassiveUpdaterPlatform.
  FlutterPassiveUpdaterPlatform() : super(token: _token);

  static final Object _token = Object();

  static FlutterPassiveUpdaterPlatform _instance = MethodChannelFlutterPassiveUpdater();

  /// The default instance of [FlutterPassiveUpdaterPlatform] to use.
  ///
  /// Defaults to [MethodChannelFlutterPassiveUpdater].
  static FlutterPassiveUpdaterPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [FlutterPassiveUpdaterPlatform] when
  /// they register themselves.
  static set instance(FlutterPassiveUpdaterPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
