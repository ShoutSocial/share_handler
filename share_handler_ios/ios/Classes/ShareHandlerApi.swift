//
//  ShareHandlerApi.swift
//  share_handler_ios
//
//  Created by Josh Juncker on 5/3/22.
//

import Foundation
import Flutter

private func wrapResult(_ result: Any?, _ error: FlutterError?) -> [String : Any?]? {
    var errorDict: [String : Any]?
    if let error = error {
        errorDict = [
            "code": error.code ,
            "message": error.message ?? NSNull(),
            "details": error.details ?? NSNull()
        ]
    }
    return ["result": result, "error": errorDict]
}

class ShareHandlerApiCodecReader: FlutterStandardReader {
    override func readValue(ofType type: UInt8) -> Any? {
        switch type {
        case 128:
            return SharedAttachment.fromMap(map: self.readValue() as? Dictionary<String, Any?>)
        case 129:
            return SharedMedia.fromMap(map: self.readValue() as? Dictionary<String, Any?>)
        case 130:
            return SharedMedia.fromMap(map: self.readValue() as? Dictionary<String, Any?>)
        default:
            return super.readValue(ofType: type)
        }
    }
}

class ShareHandlerApiCodecWriter: FlutterStandardWriter {
    override func writeValue(_ value: Any) {
        if let _value = value as? SharedAttachment {
            self.writeByte(128)
            self.writeValue(_value.toDictionary())
        } else if let _value = value as? SharedMedia {
            self.writeByte(129)
            self.writeValue(_value.toDictionary())
        } else if let _value = value as? SharedMedia {
            self.writeByte(130)
            self.writeValue(_value.toDictionary())
        } else {
            super.writeValue(value)
        }
    }
}

class ShareHandlerApiCodecReaderWriter: FlutterStandardReaderWriter {
    override func writer(with data: NSMutableData) -> FlutterStandardWriter {
        return ShareHandlerApiCodecWriter.init(data: data)
    }
    
    override func reader(with data: Data) -> FlutterStandardReader {
        ShareHandlerApiCodecReader.init(data: data)
    }
}

let ShareHandlerApiGetCodecSSharedObject: FlutterStandardMessageCodec = {
    var sSharedObject = FlutterStandardMessageCodec(readerWriter: ShareHandlerApiCodecReaderWriter())
    return sSharedObject
}()

func ShareHandlerApiGetCodec() -> (NSObjectProtocol & FlutterMessageCodec) {
    // `dispatch_once()` call was converted to a static variable initializer
    return ShareHandlerApiGetCodecSSharedObject
}

protocol ShareHandlerApi: AnyObject {
    func getInitialSharedMedia(_ error: AutoreleasingUnsafeMutablePointer<FlutterError?>) -> SharedMedia?
    func recordSentMessage(_ media: SharedMedia?, error: AutoreleasingUnsafeMutablePointer<FlutterError?>)
    func resetInitialSharedMedia(_ error: AutoreleasingUnsafeMutablePointer<FlutterError?>)
}

func ShareHandlerApiSetup(_ binaryMessenger: FlutterBinaryMessenger, _ api: (NSObjectProtocol & ShareHandlerApi)) {
    do {
        let channel = FlutterBasicMessageChannel(
            name: "dev.flutter.pigeon.ShareHandlerApi.getInitialSharedMedia",
            binaryMessenger: binaryMessenger,
            codec: ShareHandlerApiGetCodec())
//        assert(api.responds(to: Selector(("getInitialSharedMedia:"))))
        
        channel.setMessageHandler() { (message, callback) -> () in
            var error: FlutterError?
            let output = api.getInitialSharedMedia(&error)
            
            callback(wrapResult(output?.toDictionary(), error))
        }
    }
    do {
        let channel = FlutterBasicMessageChannel(
            name: "dev.flutter.pigeon.ShareHandlerApi.recordSentMessage",
            binaryMessenger: binaryMessenger,
            codec: ShareHandlerApiGetCodec())
//        assert(api.responds(to: Selector(("recordSentMessage:error:"))))
        
        channel.setMessageHandler() { (message, callback) -> () in
            var media: SharedMedia?
            if let args = message as? NSArray {
                media = args[0] as? SharedMedia
            }
            var error: FlutterError?
            
            api.recordSentMessage(media, error: &error)
            
            callback(wrapResult(nil, error))
        }
    }
    do {
        let channel = FlutterBasicMessageChannel(
            name: "dev.flutter.pigeon.ShareHandlerApi.resetInitialSharedMedia",
            binaryMessenger: binaryMessenger,
            codec: ShareHandlerApiGetCodec())
//        assert(api.responds(to: Selector(("resetInitialSharedMedia:"))))
        
        channel.setMessageHandler() { (message, callback) -> () in
            var error: FlutterError?
            api.resetInitialSharedMedia(&error)
            
            callback(wrapResult(nil, error))
        }
    }
}
