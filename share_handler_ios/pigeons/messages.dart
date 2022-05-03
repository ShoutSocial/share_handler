import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(PigeonOptions(
  dartOut: 'lib/messages.g.dart',
  objcHeaderOut: 'ios/Classes/messages.h',
  objcSourceOut: 'ios/Classes/messages.m',
  objcOptions: ObjcOptions(
    prefix: 'FLT',
  ),
  copyrightHeader: 'pigeons/copyright.txt',
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
  @ObjCSelector('getInitialSharedMedia')
  SharedMedia? getInitialSharedMedia();
  @ObjCSelector('recordSentMessage:')
  void recordSentMessage(SharedMedia media);
  @ObjCSelector('resetInitialSharedMedia')
  void resetInitialSharedMedia();
}
