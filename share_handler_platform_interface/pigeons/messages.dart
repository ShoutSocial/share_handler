import 'package:pigeon/pigeon.dart';

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
