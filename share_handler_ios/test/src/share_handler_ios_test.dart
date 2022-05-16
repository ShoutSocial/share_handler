import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:share_handler_ios/share_handler_ios.dart';

void main() {
  const channel = MethodChannel('share_handler');

  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    channel.setMockMethodCallHandler((MethodCall methodCall) async => '42');
  });

  tearDown(() {
    channel.setMockMethodCallHandler(null);
  });
}
