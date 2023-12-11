import 'package:flutter_test/flutter_test.dart';
import 'package:share_handler_linux/share_handler_linux.dart';

void main() {
  // const channel = MethodChannel('share_handler');

  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    // channel.setMockMethodCallHandler((MethodCall methodCall) async {
    //   return '42';
    // });
  });

  tearDown(() {
    // channel.setMockMethodCallHandler(null);
  });

  test('getPlatformVersion', () async {
    expect(await ShareHandlerLinuxPlatform.platformVersion, '42');
  });
}
