import 'dart:async';
import 'dart:html' as html;

import 'package:flutter/foundation.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:share_handler_platform_interface/share_handler_platform_interface.dart';

/// The web implementation of [ShareHandlerPlatform].
///
/// This class implements the `package:share_handler`
/// functionality for the web.
class ShareHandlerWebPlatform extends ShareHandlerPlatform {
  /// Registers this class as the default instance of [ShareHandlerPlatform].
  static void registerWith(Registrar registrar) {
    ShareHandlerPlatform.instance = ShareHandlerWebPlatform();
  }

  /// The current browser window.
  @visibleForTesting
  html.Window? window;

  html.Window get _window => window ?? html.window;

  /// Returns a [String] containing the version of the platform.
  Future<String> get getPlatformVersion {
    return Future.value(_window.navigator.userAgent);
  }
}
