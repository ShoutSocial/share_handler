public enum SharedAttachmentType: Int, Codable {
    case image
    case video
    case audio
    case file
}

open class SharedAttachment: Codable {
    public var path: String
    public var type: SharedAttachmentType
    
    public init(path: String, type: SharedAttachmentType) {
        self.path = path
        self.type = type
    }
    
    public func toDictionary() -> Dictionary<String, Any> {
        return ["path": path, "type": type.rawValue]
    }
    
    public class func fromMap(map: Dictionary<String, Any?>?) -> SharedAttachment? {
        if let _map = map {
            return SharedAttachment.init(path: _map["path"] as! String, type: SharedAttachmentType.init(rawValue: _map["type"] as! Int)!)
        } else {
            return nil
        }
    }
}

open class SharedMedia: Codable {
    public var attachments: [SharedAttachment]?
    public var conversationIdentifier: String?
    public var content: String?
    public var speakableGroupName: String?
    public var serviceName: String?
    public var senderIdentifier: String?
    public var imageFilePath: String?

    public init(attachments: [SharedAttachment]?, conversationIdentifier: String?, content: String?, speakableGroupName: String?, serviceName: String?, senderIdentifier: String?, imageFilePath: String?) {
        self.attachments = attachments
        self.conversationIdentifier = conversationIdentifier
        self.content = content
        self.speakableGroupName = speakableGroupName
        self.serviceName = serviceName
        self.senderIdentifier = senderIdentifier
        self.imageFilePath = imageFilePath
    }
    
    public class func fromMap(map: Dictionary<String, Any?>?) -> SharedMedia? {
        if let _map = map {
            return SharedMedia(attachments: (_map["attachments"] as? Array<Dictionary<String,Any>>)?.compactMap{ SharedAttachment.fromMap(map: $0)}, conversationIdentifier: _map["conversationIdentifier"] as? String, content: _map["content"] as? String, speakableGroupName: _map["speakableGroupName"] as? String, serviceName: _map["serviceName"]as? String, senderIdentifier: _map["senderIdentifier"] as? String, imageFilePath: _map["imageFilePath"] as? String)
        } else {
            return nil
        }
    }
    
    public class func fromJson(data: Data?) -> SharedMedia? {
        if let _json = data {
            let map = try? JSONSerialization.jsonObject(with: _json) as? Dictionary<String,Any>
            if let _map = map {
                return SharedMedia(attachments: (_map["attachments"] as? Array<Dictionary<String,Any>>)?.map{ SharedAttachment(path: $0["path"] as! String, type: SharedAttachmentType(rawValue: $0["type"] as! Int? ?? SharedAttachmentType.file.rawValue) ?? SharedAttachmentType.file )}, conversationIdentifier: _map["conversationIdentifier"] as? String, content: _map["content"] as? String, speakableGroupName: _map["speakableGroupName"] as? String, serviceName: _map["serviceName"]as? String, senderIdentifier: _map["senderIdentifier"] as? String, imageFilePath: _map["imageFilePath"] as? String)
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
