import 'package:flutter/services.dart';
import 'package:share_handler_platform_interface/share_handler_platform_interface.dart';

/// An implementation of [ShareHandlerPlatform]
/// that uses a `MethodChannel` to communicate with the native code.
///
/// The `share_handler` plugin code
/// itself never talks to the native code directly.
/// It delegates all calls to an instance of a class
/// that extends the [ShareHandlerPlatform].
///
/// The architecture above allows for platforms that communicate differently
/// with the native side (like web) to have a common interface to extend.
///
/// This is the instance that runs when the native side talks
/// to your Flutter app through MethodChannels (Android and iOS platforms).
class MethodChannelShareHandler extends ShareHandlerPlatform {
  final ShareHandlerApi _api = ShareHandlerApi();
  static const EventChannel eventChannel =
      EventChannel("com.shoutsocial.share_handler/sharedMediaStream");
  static Stream<SharedMedia>? _sharedMediaStream;

  @override
  Future<SharedMedia?> getInitialSharedMedia() async {
    final SharedMedia? result = await _api.getInitialSharedMedia();
    return result;
  }

  @override
  Future<void> recordSentMessage({
    required String conversationIdentifier,
    required String conversationName,
    String? conversationImageFilePath,
    String? serviceName,
  }) {
    return _api.recordSentMessage(SharedMedia(
      conversationIdentifier: conversationIdentifier,
      speakableGroupName: conversationName,
      serviceName: serviceName,
      imageFilePath: conversationImageFilePath,
    ));
  }

  @override
  Future<void> resetInitialSharedMedia() {
    return _api.resetInitialSharedMedia();
  }

  @override
  Stream<SharedMedia> get sharedMediaStream {
    _sharedMediaStream ??=
        eventChannel.receiveBroadcastStream().map<SharedMedia>((dynamic event) {
      final Map<dynamic, dynamic> map = event as Map<dynamic, dynamic>;
      return SharedMedia.decode(map);
    });

    return _sharedMediaStream!;
  }
}
