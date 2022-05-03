import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:share_handler_platform_interface/messages.dart';
import 'package:share_handler_platform_interface/share_handler_platform_interface.dart';

class ShareHandlerIos extends ShareHandlerPlatform {
  // static const MethodChannel _channel = MethodChannel('share_handler_ios');

  // static Future<String?> get platformVersion async {
  //   final String? version = await _channel.invokeMethod('getPlatformVersion');
  //   return version;
  // }

  final ShareHandlerApi _api = ShareHandlerApi();
  static const EventChannel eventChannel = EventChannel("com.shoutsocial.share_handler/sharedMediaStream");
  static Stream<SharedMedia>? _sharedMediaStream;

  static void registerWith() {
    ShareHandlerPlatform.instance = ShareHandlerIos();
  }

  @override
  Future<SharedMedia?> getInitialSharedMedia() async {
    final SharedMedia? result = await _api.getInitialSharedMedia();
    return result;
  }

  @override
  Future<void> recordSentMessage({
    required String conversationIdentifier,
    required String conversationName,
    File? conversationImage,
    String? serviceName,
  }) {
    return _api.recordSentMessage(SharedMedia(
      conversationIdentifier: conversationIdentifier,
      speakableGroupName: conversationName,
      serviceName: serviceName,
      imageFilePath: conversationImage?.absolute.path,
    ));
  }

  @override
  Future<void> resetInitialSharedMedia() {
    return _api.resetInitialSharedMedia();
  }

  @override
  Stream<SharedMedia> get sharedMediaStream {
    _sharedMediaStream ??= eventChannel.receiveBroadcastStream().map<SharedMedia>((dynamic event) {
      final Map<dynamic, dynamic> map = event as Map<dynamic, dynamic>;
      return SharedMedia.decode(map);
    });
    // if (_sharedMediaStream == null) {
    //   final stream = eventChannel.receiveBroadcastStream().map((dynamic event) {
    //     final Map<dynamic, dynamic> map = event as Map<dynamic, dynamic>;
    //   });
    //   cast<String?>();
    //   _sharedMediaStream = stream.transform<SharedMedia>(
    //     StreamTransformer<String?, SharedMedia>.fromHandlers(
    //       handleData: (String? data, EventSink<SharedMedia> sink) {
    //         if (data != null) {
    //           final map = jsonDecode(data);
    //           sink.add(SharedMedia.decode(map));
    //         }
    //       },
    //     ),
    //   );
    // }
    return _sharedMediaStream!;
  }
}
