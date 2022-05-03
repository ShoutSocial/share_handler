//
//  FLTShareHandlerApi.swift
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

class FLTShareHandlerApiCodecReader: FlutterStandardReader {
    override func readValue(ofType type: UInt8) -> Any? {
        switch type {
        case 128:
            return FLTSharedAttachment.fromMap(map: self.readValue() as? Dictionary<String, Any?>)
        case 129:
            return FLTSharedMedia.fromMap(map: self.readValue() as? Dictionary<String, Any?>)
        case 130:
            return FLTSharedMedia.fromMap(map: self.readValue() as? Dictionary<String, Any?>)
        default:
            return super.readValue(ofType: type)
        }
    }
}

class FLTShareHandlerApiCodecWriter: FlutterStandardWriter {
    override func writeValue(_ value: Any) {
        if let _value = value as? FLTSharedAttachment {
            self.writeByte(128)
            self.writeValue(_value.toDictionary())
        } else if let _value = value as? FLTSharedMedia {
            self.writeByte(129)
            self.writeValue(_value.toDictionary())
        } else if let _value = value as? FLTSharedMedia {
            self.writeByte(130)
            self.writeValue(_value.toDictionary())
        } else {
            super.writeValue(value)
        }
    }
}

class FLTShareHandlerApiCodecReaderWriter: FlutterStandardReaderWriter {
    override func writer(with data: NSMutableData) -> FlutterStandardWriter {
        return FLTShareHandlerApiCodecWriter.init(data: data)
    }
    
    override func reader(with data: Data) -> FlutterStandardReader {
        FLTShareHandlerApiCodecReader.init(data: data)
    }
}

let FLTShareHandlerApiGetCodecSSharedObject: FlutterStandardMessageCodec = {
    var sSharedObject = FlutterStandardMessageCodec(readerWriter: FLTShareHandlerApiCodecReaderWriter())
    return sSharedObject
}()

func FLTShareHandlerApiGetCodec() -> (NSObjectProtocol & FlutterMessageCodec) {
    // `dispatch_once()` call was converted to a static variable initializer
    return FLTShareHandlerApiGetCodecSSharedObject
}

protocol FLTShareHandlerApi: AnyObject {
    func getInitialSharedMedia(_ error: AutoreleasingUnsafeMutablePointer<FlutterError?>) -> FLTSharedMedia?
    func recordSentMessage(_ media: FLTSharedMedia?, error: AutoreleasingUnsafeMutablePointer<FlutterError?>)
    func resetInitialSharedMedia(_ error: AutoreleasingUnsafeMutablePointer<FlutterError?>)
}

func FLTShareHandlerApiSetup(_ binaryMessenger: FlutterBinaryMessenger, _ api: (NSObjectProtocol & FLTShareHandlerApi)) {
    do {
        let channel = FlutterBasicMessageChannel(
            name: "dev.flutter.pigeon.ShareHandlerApi.getInitialSharedMedia",
            binaryMessenger: binaryMessenger,
            codec: FLTShareHandlerApiGetCodec())
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
            codec: FLTShareHandlerApiGetCodec())
//        assert(api.responds(to: Selector(("recordSentMessage:error:"))))
        
        channel.setMessageHandler() { (message, callback) -> () in
            var media: FLTSharedMedia?
            if let args = message as? NSArray {
                media = args[0] as? FLTSharedMedia
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
            codec: FLTShareHandlerApiGetCodec())
//        assert(api.responds(to: Selector(("resetInitialSharedMedia:"))))
        
        channel.setMessageHandler() { (message, callback) -> () in
            var error: FlutterError?
            api.resetInitialSharedMedia(&error)
            
            callback(wrapResult(nil, error))
        }
    }
}
