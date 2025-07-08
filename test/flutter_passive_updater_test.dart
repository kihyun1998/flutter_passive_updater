import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_passive_updater/flutter_passive_updater.dart';
import 'package:flutter_passive_updater/flutter_passive_updater_platform_interface.dart';
import 'package:flutter_passive_updater/flutter_passive_updater_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockFlutterPassiveUpdaterPlatform
    with MockPlatformInterfaceMixin
    implements FlutterPassiveUpdaterPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final FlutterPassiveUpdaterPlatform initialPlatform = FlutterPassiveUpdaterPlatform.instance;

  test('$MethodChannelFlutterPassiveUpdater is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelFlutterPassiveUpdater>());
  });

  test('getPlatformVersion', () async {
    FlutterPassiveUpdater flutterPassiveUpdaterPlugin = FlutterPassiveUpdater();
    MockFlutterPassiveUpdaterPlatform fakePlatform = MockFlutterPassiveUpdaterPlatform();
    FlutterPassiveUpdaterPlatform.instance = fakePlatform;

    expect(await flutterPassiveUpdaterPlugin.getPlatformVersion(), '42');
  });
}
