import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:share_handler/share_handler.dart';

class MockShareHandlerPlatform extends Mock implements ShareHandlerPlatform {}

void main() {
  group('ShareHandler', () {
    test('can be instantiated', () {
      expect(
        ShareHandler.instance,
        isNotNull,
      );
    });
  });
}
