import 'dart:html';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:share_handler_platform_interface/share_handler_platform_interface.dart';
import 'package:share_handler_web/share_handler_web.dart';

class MockWindow extends Mock implements Window {}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('ShareHandlerWebPlatform', () {
    late Window window;

    setUp(() async {
      window = MockWindow();

      ShareHandlerPlatform.instance = ShareHandlerWebPlatform()..window = window;
    });

    testWidgets('ShareHandlerWebPlatform is the live instance', (tester) async {
      expect(ShareHandlerPlatform.instance, isA<ShareHandlerWebPlatform>());
    });
  });
}
