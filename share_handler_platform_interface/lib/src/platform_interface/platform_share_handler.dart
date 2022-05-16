import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:share_handler_platform_interface/share_handler_platform_interface.dart';

abstract class ShareHandlerPlatform extends PlatformInterface {
  /// Constructs a [ShareHandlerPlatform].
  ShareHandlerPlatform() : super(token: _token);

  static final Object _token = Object();

  static ShareHandlerPlatform _instance = MethodChannelShareHandler();

  /// The default instance of [ShareHandlerPlatform] to use.
  ///
  /// Defaults to [MethodChannelShareHandler].
  static ShareHandlerPlatform get instance => _instance;

  /// Platform-specific plugins should set this with their own platform-specific
  /// class that extends [ShareHandlerPlatform] when they register themselves.
  static set instance(ShareHandlerPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
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
    String? conversationImageFilePath,
    String? serviceName,
  }) {
    throw UnimplementedError('recordSentMessage has not been implemented.');
  }

  /// Resets the initial shared media to null to prevent duplicate handling.
  Future<void> resetInitialSharedMedia() {
    throw UnimplementedError('resetInitialSharedMedia has not been implemented.');
  }

  /// Stream that can be listened to for shared media when the app is already running.
  Stream<SharedMedia> get sharedMediaStream => throw UnimplementedError('mediaStream has not been implemented.');
}
