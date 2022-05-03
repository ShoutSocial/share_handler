import 'dart:io';

import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:share_handler_platform_interface/messages.dart';

import 'method_channel_share_handler.dart';

/// The interface that implementations of share_handler must implement.
///
/// Platform implementations should extend this class rather than implement it as `share_handler`
/// does not consider newly added methods to be breaking changes. Extending this class
/// (using `extends`) ensures that the subclass will get the default implementation, while
/// platform implementations that `implements` this interface will be broken by newly added
/// [ShareHandlerPlatform] methods.
abstract class ShareHandlerPlatform extends PlatformInterface {
  static final Object _token = Object();

  /// Constructs a ShareHandlerPlatform.
  ShareHandlerPlatform() : super(token: _token);

  static ShareHandlerPlatform _instance = MethodChannelShareHandler();

  /// The default instance of [ShareHandlerPlatform] to use.
  ///
  /// Defaults to [MethodChannelShareHandler].
  static ShareHandlerPlatform get instance => _instance;

  /// Platform-specific plugins should override this with their own
  /// platform-specific class that extends [VideoPlayerPlatform] when they
  /// register themselves.
  static set instance(ShareHandlerPlatform instance) {
    PlatformInterface.verify(instance, _token);
    _instance = instance;
  }

  /// Returns the initially stored shared media for single time use on app boot. Use media stream to receive shares while app is active.
  /// NOTE. (iOS only) file attachments are copied to a temp folder and should be deleted after using them.
  Future<SharedMedia?> getInitialSharedMedia() async {
    throw UnimplementedError('getInitialSharedMedia has not been implemented.');
  }

  /// Records a sent message so the share menu can suggest recipients/conversations to share to.
  Future<void> recordSentMessage({
    required String conversationIdentifier,
    required String conversationName,
    File? conversationImage,
    String? serviceName,
  }) {
    throw UnimplementedError('recordSentMessage has not been implemented.');
  }

  /// Resets the initial shared media to null to prevent duplicate handling.
  Future<void> resetInitialSharedMedia() {
    throw UnimplementedError('resetInitialSharedMedia has not been implemented.');
  }

  Stream<SharedMedia> get sharedMediaStream => throw UnimplementedError('mediaStream has not been implemented.');
}
