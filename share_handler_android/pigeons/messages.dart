import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(PigeonOptions(
  dartOut: 'lib/messages.g.dart',
  javaOut: 'android/src/main/java/com/shoutsocial/share_handler_android/Messages.java',
  javaOptions: JavaOptions(
    package: 'com.shoutsocial.share_handler_android',
  ),
))
enum SharedAttachmentType {
  image,
  video,
  audio,
  file,
}

class SharedAttachment {
  final String path;
  final SharedAttachmentType type;

  SharedAttachment({
    required this.path,
    required this.type,
  });
}

class SharedMedia {
  final List<SharedAttachment?>? attachments;
  final String? conversationIdentifier;
  final String? content;
  final String? speakableGroupName;
  final String? serviceName;
  final String? senderIdentifier;
  final String? imageFilePath;

  SharedMedia({
    this.attachments,
    this.conversationIdentifier,
    this.content,
    this.speakableGroupName,
    this.serviceName,
    this.senderIdentifier,
    this.imageFilePath,
  });
}

@HostApi()
abstract class ShareHandlerApi {
  @async
  SharedMedia? getInitialSharedMedia();
  void recordSentMessage(SharedMedia media);
  void resetInitialSharedMedia();
}
