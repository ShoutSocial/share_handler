import 'dart:async';

import 'package:flutter/services.dart';
import 'package:share_handler_platform_interface/share_handler_platform_interface.dart';

class ShareHandlerWindowsPlatform extends ShareHandlerPlatform {
  static const _channel = MethodChannel('share_handler');

  static Future<String?> get platformVersion async {
    final version = await _channel.invokeMethod<String?>('getPlatformVersion');
    return version;
  }
}
