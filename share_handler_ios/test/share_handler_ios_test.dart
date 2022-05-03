import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:share_handler_ios/share_handler_ios.dart';

void main() {
  const MethodChannel channel = MethodChannel('share_handler_ios');

  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    channel.setMockMethodCallHandler((MethodCall methodCall) async {
      return '42';
    });
  });

  tearDown(() {
    channel.setMockMethodCallHandler(null);
  });

  test('getPlatformVersion', () async {
    // expect(await ShareHandlerIos.platformVersion, '42');
  });
}
