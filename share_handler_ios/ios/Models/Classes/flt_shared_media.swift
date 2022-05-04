public enum FLTSharedAttachmentType: Int, Codable {
    case image
    case video
    case audio
    case file
}

public class FLTSharedAttachment: Codable {
    var path: String
    var type: FLTSharedAttachmentType
    
    public init(path: String, type: FLTSharedAttachmentType) {
        self.path = path
        self.type = type
    }
    
    public func toDictionary() -> Dictionary<String, Any> {
        return ["path": path, "type": type.rawValue]
    }
    
    class func fromMap(map: Dictionary<String, Any?>?) -> FLTSharedAttachment? {
        if let _map = map {
            return FLTSharedAttachment.init(path: _map["path"] as! String, type: FLTSharedAttachmentType.init(rawValue: _map["type"] as! Int)!)
        } else {
            return nil
        }
    }
}

public class FLTSharedMedia: Codable {
    var attachments: [FLTSharedAttachment]?
    var conversationIdentifier: String?
    var content: String?
    var speakableGroupName: String?
    var serviceName: String?
    var senderIdentifier: String?
    var imageFilePath: String?
    
    public init(attachments: [FLTSharedAttachment]?, conversationIdentifier: String?, content: String?, speakableGroupName: String?, serviceName: String?, senderIdentifier: String?, imageFilePath: String?) {
        self.attachments = attachments
        self.conversationIdentifier = conversationIdentifier
        self.content = content
        self.speakableGroupName = speakableGroupName
        self.serviceName = serviceName
        self.senderIdentifier = senderIdentifier
        self.imageFilePath = imageFilePath
    }
    
    class func fromMap(map: Dictionary<String, Any?>?) -> FLTSharedMedia? {
        if let _map = map {
            return FLTSharedMedia(attachments: (_map["attachments"] as? Array<Dictionary<String,Any>>)?.compactMap{ FLTSharedAttachment.fromMap(map: $0)}, conversationIdentifier: _map["conversationIdentifier"] as? String, content: _map["content"] as? String, speakableGroupName: _map["speakableGroupName"] as? String, serviceName: _map["serviceName"]as? String, senderIdentifier: _map["senderIdentifier"] as? String, imageFilePath: _map["imageFilePath"] as? String)
        } else {
            return nil
        }
    }
    
    class func fromJson(data: Data?) -> FLTSharedMedia? {
        if let _json = data {
            let map = try? JSONSerialization.jsonObject(with: _json) as? Dictionary<String,Any>
            if let _map = map {
                return FLTSharedMedia(attachments: (_map["attachments"] as? Array<Dictionary<String,Any>>)?.map{ FLTSharedAttachment(path: $0["path"] as! String, type: FLTSharedAttachmentType(rawValue: $0["type"] as! Int? ?? FLTSharedAttachmentType.file.rawValue) ?? FLTSharedAttachmentType.file )}, conversationIdentifier: _map["conversationIdentifier"] as? String, content: _map["content"] as? String, speakableGroupName: _map["speakableGroupName"] as? String, serviceName: _map["serviceName"]as? String, senderIdentifier: _map["senderIdentifier"] as? String, imageFilePath: _map["imageFilePath"] as? String)
            }
        }
        return nil
    }
    
    public func toDictionary() -> Dictionary<String, Any?> {
        return ["attachments": attachments?.map {$0.toDictionary()}, "conversationIdentifier": conversationIdentifier, "content": content, "speakableGroupName": speakableGroupName, "serviceName": serviceName, "senderIdentifier": senderIdentifier, "imageFilePath": imageFilePath]
    }
    
    public func toJson() -> Data {
        var data: Data?
        do {
            data = try JSONEncoder().encode(self)
        } catch {
            print("failed to encode SharedMedia")
        }
        return data!
    }
}
