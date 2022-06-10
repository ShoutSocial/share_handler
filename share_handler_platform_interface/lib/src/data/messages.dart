import 'dart:async';

import 'package:flutter/foundation.dart' show WriteBuffer, ReadBuffer;
import 'package:flutter/services.dart';

enum SharedAttachmentType {
  image,
  video,
  audio,
  file,
}

class SharedAttachment {
  SharedAttachment({
    required this.path,
    required this.type,
  });

  /// The path to the file on device
  String path;
  SharedAttachmentType type;

  Object encode() {
    final Map<Object?, Object?> pigeonMap = <Object?, Object?>{};
    pigeonMap['path'] = path;
    pigeonMap['type'] = type.index;
    return pigeonMap;
  }

  static SharedAttachment decode(Object message) {
    final Map<Object?, Object?> pigeonMap = message as Map<Object?, Object?>;
    return SharedAttachment(
      path: Uri.decodeFull(pigeonMap['path']! as String),
      type: SharedAttachmentType.values[pigeonMap['type']! as int],
    );
  }
}

class SharedMedia {
  SharedMedia({
    this.attachments,
    this.recipientIdentifiers,
    this.conversationIdentifier,
    this.content,
    this.speakableGroupName,
    this.serviceName,
    this.senderIdentifier,
    this.imageFilePath,
  });

  /// List of shared attachments (ex. images, videos, pdfs, etc.). Each attachment has an attachment type and a path to the file on the device.
  List<SharedAttachment?>? attachments;

  /// iOS only: List of recipient identifiers from iOS intent.
  List<String?>? recipientIdentifiers;

  /// The identifier of the conversation that content was shared to. This will come back if you use the 'recordSentMessage' method, and the user selects a specific conversation to share content to.
  String? conversationIdentifier;

  /// Text content that was shared if any. Could be a url as well.
  String? content;

  /// The name of the recipient the content was shared to if specified.
  String? speakableGroupName;

  /// iOS only: The name of the service that sent the content.
  String? serviceName;

  /// iOS only: The identifier of the sender that shared the content.
  String? senderIdentifier;

  /// iOS only: The file path for the image of the sender.
  String? imageFilePath;

  Object encode() {
    final Map<Object?, Object?> pigeonMap = <Object?, Object?>{};
    pigeonMap['attachments'] = attachments;
    pigeonMap['recipientIdentifiers'] = recipientIdentifiers;
    pigeonMap['conversationIdentifier'] = conversationIdentifier;
    pigeonMap['content'] = content;
    pigeonMap['speakableGroupName'] = speakableGroupName;
    pigeonMap['serviceName'] = serviceName;
    pigeonMap['senderIdentifier'] = senderIdentifier;
    pigeonMap['imageFilePath'] = imageFilePath;
    return pigeonMap;
  }

  static SharedMedia decode(Object message) {
    final Map<Object?, Object?> pigeonMap = message as Map<Object?, Object?>;
    return SharedMedia(
      attachments: (pigeonMap['attachments'] as List<Object?>?)
          ?.map((e) => SharedAttachment.decode(e as Map<Object?, Object?>))
          .cast<SharedAttachment?>()
          .toList(),
      recipientIdentifiers: (pigeonMap['recipientIdentifiers'] as List<Object?>?)?.cast<String?>(),
      conversationIdentifier: pigeonMap['conversationIdentifier'] as String?,
      content: pigeonMap['content'] as String?,
      speakableGroupName: pigeonMap['speakableGroupName'] as String?,
      serviceName: pigeonMap['serviceName'] as String?,
      senderIdentifier: pigeonMap['senderIdentifier'] as String?,
      imageFilePath: pigeonMap['imageFilePath'] as String?,
    );
  }
}

class _ShareHandlerApiCodec extends StandardMessageCodec {
  const _ShareHandlerApiCodec();
  @override
  void writeValue(WriteBuffer buffer, Object? value) {
    if (value is SharedAttachment) {
      buffer.putUint8(128);
      writeValue(buffer, value.encode());
    } else if (value is SharedMedia) {
      buffer.putUint8(129);
      writeValue(buffer, value.encode());
    } else if (value is SharedMedia) {
      buffer.putUint8(130);
      writeValue(buffer, value.encode());
    } else {
      super.writeValue(buffer, value);
    }
  }

  @override
  Object? readValueOfType(int type, ReadBuffer buffer) {
    switch (type) {
      case 128:
        return SharedAttachment.decode(readValue(buffer)!);

      case 129:
        return SharedMedia.decode(readValue(buffer)!);

      case 130:
        return SharedMedia.decode(readValue(buffer)!);

      default:
        return super.readValueOfType(type, buffer);
    }
  }
}

class ShareHandlerApi {
  /// Constructor for [ShareHandlerApi].  The [binaryMessenger] named argument is
  /// available for dependency injection.  If it is left null, the default
  /// BinaryMessenger will be used which routes to the host platform.
  ShareHandlerApi({BinaryMessenger? binaryMessenger}) : _binaryMessenger = binaryMessenger;

  final BinaryMessenger? _binaryMessenger;

  static const MessageCodec<Object?> codec = _ShareHandlerApiCodec();

  Future<SharedMedia?> getInitialSharedMedia() async {
    final BasicMessageChannel<Object?> channel = BasicMessageChannel<Object?>(
        'dev.flutter.pigeon.ShareHandlerApi.getInitialSharedMedia', codec,
        binaryMessenger: _binaryMessenger);
    final Map<Object?, Object?>? replyMap = await channel.send(null) as Map<Object?, Object?>?;
    if (replyMap == null) {
      throw PlatformException(
        code: 'channel-error',
        message: 'Unable to establish connection on channel.',
      );
    } else if (replyMap['error'] != null) {
      final Map<Object?, Object?> error = (replyMap['error'] as Map<Object?, Object?>?)!;
      throw PlatformException(
        code: (error['code'] as String?)!,
        message: error['message'] as String?,
        details: error['details'],
      );
    } else if (replyMap['result'] != null) {
      if (replyMap['result'] is SharedMedia) {
        return replyMap['result'] as SharedMedia;
      }

      return SharedMedia.decode(replyMap['result']!);
    } else {
      return null;
    }
  }

  Future<void> recordSentMessage(SharedMedia argMedia) async {
    final BasicMessageChannel<Object?> channel = BasicMessageChannel<Object?>(
        'dev.flutter.pigeon.ShareHandlerApi.recordSentMessage', codec,
        binaryMessenger: _binaryMessenger);
    final Map<Object?, Object?>? replyMap = await channel.send(<Object?>[argMedia]) as Map<Object?, Object?>?;
    if (replyMap == null) {
      throw PlatformException(
        code: 'channel-error',
        message: 'Unable to establish connection on channel.',
      );
    } else if (replyMap['error'] != null) {
      final Map<Object?, Object?> error = (replyMap['error'] as Map<Object?, Object?>?)!;
      throw PlatformException(
        code: (error['code'] as String?)!,
        message: error['message'] as String?,
        details: error['details'],
      );
    } else {
      return;
    }
  }

  Future<void> resetInitialSharedMedia() async {
    final BasicMessageChannel<Object?> channel = BasicMessageChannel<Object?>(
        'dev.flutter.pigeon.ShareHandlerApi.resetInitialSharedMedia', codec,
        binaryMessenger: _binaryMessenger);
    final Map<Object?, Object?>? replyMap = await channel.send(null) as Map<Object?, Object?>?;
    if (replyMap == null) {
      throw PlatformException(
        code: 'channel-error',
        message: 'Unable to establish connection on channel.',
      );
    } else if (replyMap['error'] != null) {
      final Map<Object?, Object?> error = (replyMap['error'] as Map<Object?, Object?>?)!;
      throw PlatformException(
        code: (error['code'] as String?)!,
        message: error['message'] as String?,
        details: error['details'],
      );
    } else {
      return;
    }
  }
}
