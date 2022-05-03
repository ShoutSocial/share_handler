// class SharedMedia {
//   final List<SharedAttachment>? attachments;
//   final List<String>? recipientIdentifiers;
//   final String? conversationIdentifier;
//   final String? content;
//   final String? speakableGroupName;
//   final String? serviceName;
//   final String? senderIdentifier;
//   final String? imageFilePath;

//   SharedMedia({
//     this.attachments,
//     this.recipientIdentifiers,
//     this.conversationIdentifier,
//     this.content,
//     this.speakableGroupName,
//     this.serviceName,
//     this.senderIdentifier,
//     this.imageFilePath,
//   });

//   SharedMedia.fromJson(Map<String, dynamic> json)
//       : recipientIdentifiers = json['recipientIdentifiers']?.cast<String>(),
//         attachments = json['attachments']?.map((e) => SharedAttachment.fromJson(e))?.toList(),
//         conversationIdentifier = json['conversationIdentifier'],
//         content = json['content'],
//         speakableGroupName = json['speakableGroupName'],
//         serviceName = json['serviceName'],
//         senderIdentifier = json['senderIdentifier'],
//         imageFilePath = json['imageFilePath'];
// }

// class SharedAttachment {
//   final String path;
//   final SharedAttachmentType type;

//   SharedAttachment({
//     required this.path,
//     required this.type,
//   });

//   SharedAttachment.fromJson(Map<String, dynamic> json)
//       : path = json['path'],
//         type = SharedAttachmentType.values.byName(json['type']);
// }

// enum SharedAttachmentType {
//   image,
//   video,
//   audio,
//   file,
// }
