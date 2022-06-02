import Flutter
import UIKit
import Photos
import Intents

public class SwiftShareHandlerIosPlatform: NSObject, FlutterPlugin, FlutterStreamHandler, ShareHandlerApi {
    
    
//     public static func register(with registrar: FlutterPluginRegistrar) {
//       let channel = FlutterMethodChannel(name: "share_handler_ios", binaryMessenger: registrar.messenger())
//       let instance = SwiftShareHandlerPlugin()
//       registrar.addMethodCallDelegate(instance, channel: channel)
//     }

    static let kEventsChannel = "com.shoutsocial.share_handler/sharedMediaStream"

    private var customSchemePrefix = "ShareMedia"

    private var initialMedia: SharedMedia? = nil
    private var latestMedia: SharedMedia? = nil

    private var eventSink: FlutterEventSink? = nil;

    // Singleton is required for calling functions directly from AppDelegate
    // - it is required if the developer is using also another library, which requires to call "application(_:open:options:)"
    // -> see Example app
    public static let instance = SwiftShareHandlerIosPlatform()

    public static func register(with registrar: FlutterPluginRegistrar) {
        let messenger : FlutterBinaryMessenger = registrar.messenger()
        let api : ShareHandlerApi & NSObjectProtocol = instance
        ShareHandlerApiSetup(messenger, api)

        let eventsChannel = FlutterEventChannel(name: kEventsChannel, binaryMessenger: messenger)
        eventsChannel.setStreamHandler(instance)

        registrar.addApplicationDelegate(instance)
    }

    public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        eventSink = events
        return nil
    }

    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        eventSink = nil
        return nil
    }

    // By Adding bundle id to prefix, we'll ensure that the correct application will be openned
    // - found the issue while developing multiple applications using this library, after "application(_:open:options:)" is called, the first app using this librabry (first app by bundle id alphabetically) is opened
    public func hasMatchingSchemePrefix(url: URL?) -> Bool {
        if let url = url, let appDomain = Bundle.main.bundleIdentifier {
            return url.absoluteString.hasPrefix("\(self.customSchemePrefix)-\(appDomain)") || url.absoluteString.hasPrefix("file://")
        }
        return false
    }

    // This is the function called on app startup with a shared link if the app had been closed already.
    // It is called as the launch process is finishing and the app is almost ready to run.
    // If the URL includes the module's ShareMedia prefix, then we process the URL and return true if we know how to handle that kind of URL or false if the app is not able to.
    // If the URL does not include the module's prefix, we must return true since while our module cannot handle the link, other modules might be and returning false can prevent
    // them from getting the chance to.
    // Reference: https://developer.apple.com/documentation/uikit/uiapplicationdelegate/1622921-application
    public func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [AnyHashable : Any] = [:]) -> Bool {
        if let url = launchOptions[UIApplication.LaunchOptionsKey.url] as? URL {
            if (hasMatchingSchemePrefix(url: url)) {
                return handleUrl(url: url, setInitialData: true)
            }
            return true
        } else if let activityDictionary = launchOptions[UIApplication.LaunchOptionsKey.userActivityDictionary] as? [AnyHashable: Any] {
            // Handle multiple URLs shared in
            for key in activityDictionary.keys {
                if let userActivity = activityDictionary[key] as? NSUserActivity {
                    if let url = userActivity.webpageURL {
                        if (hasMatchingSchemePrefix(url: url)) {
                            return handleUrl(url: url, setInitialData: true)
                        }
                        return true
                    }
                }
            }
        }
        return true
    }

    // This is the function called on resuming the app from a shared link.
    // It handles requests to open a resource by a specified URL. Returning true means that it was handled successfully, false means the attempt to open the resource failed.
    // If the URL includes the module's ShareMedia prefix, then we process the URL and return true if we know how to handle that kind of URL or false if we are not able to.
    // If the URL does not include the module's prefix, then we return false to indicate our module's attempt to open the resource failed and others should be allowed to.
    // Reference: https://developer.apple.com/documentation/uikit/uiapplicationdelegate/1623112-application
    public func application(_ application: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        if (hasMatchingSchemePrefix(url: url)) {
            return handleUrl(url: url, setInitialData: false)
        }
        return false
    }

    // This function is called by other modules like Firebase DeepLinks.
    // It tells the delegate that data for continuing an activity is available. Returning true means that our module handled the activity and that others do not have to. Returning false tells
    // iOS that our app did not handle the activity.
    // If the URL includes the module's ShareMedia prefix, then we process the URL and return true if we know how to handle that kind of URL or false if we are not able to.
    // If the URL does not include the module's prefix, then we must return false to indicate that this module did not handle the prefix and that other modules should try to.
    // Reference: https://developer.apple.com/documentation/uikit/uiapplicationdelegate/1623072-application
    public func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([Any]) -> Void) -> Bool {
        if let url = userActivity.webpageURL {
            if (hasMatchingSchemePrefix(url: url)) {
                return handleUrl(url: url, setInitialData: true)
            }
        }
        return false
    }

    private func handleUrl(url: URL?, setInitialData: Bool) -> Bool {
        if let url = url {
//            let appDomain = Bundle.main.bundleIdentifier!
            let appGroupId = (Bundle.main.object(forInfoDictionaryKey: "AppGroupId") as? String) ?? "group.\(Bundle.main.bundleIdentifier!)"
            let userDefaults = UserDefaults(suiteName: appGroupId)
            
            var sharedMedia: SharedMedia?

            let params = url.queryDictionary
            if let sharedPreferencesKey = params?["key"] {
                if let data = userDefaults?.object(forKey: sharedPreferencesKey) as? Data {
                    sharedMedia = try? JSONDecoder().decode(SharedMedia.self, from: data)
                }
            } else if url.absoluteString.hasPrefix("file://") {
                sharedMedia = SharedMedia.init(attachments: [SharedAttachment.init(path: url.absoluteString, type: SharedAttachmentType.file)], conversationIdentifier: nil, content: nil, speakableGroupName: nil, serviceName: nil, senderIdentifier: nil, imageFilePath: nil)
            }
            
            if let media = sharedMedia {
                media.attachments?.forEach {$0.path = getAbsolutePath(for: $0.path) ?? $0.path}
                latestMedia = media
                if (setInitialData) {
                    initialMedia = media
                }
                let map = media.toDictionary()
                eventSink?(map)
                
                return true
            }
            
            
            
            

//            if url.fragment == "media" {
//                if let key = url.host?.components(separatedBy: "=").last,
//                   let json = userDefaults?.object(forKey: key) as? Data {
//                    let sharedMedia = SharedMedia.fromMap(nil)
//                    let sharedMediaFiles: [SharedMediaFile] = sharedArray.compactMap {
//                        guard let path = getAbsolutePath(for: $0.path) else {
//                            return nil
//                        }
//                        if ($0.type == .video && $0.thumbnail != nil) {
//                            let thumbnail = getAbsolutePath(for: $0.thumbnail!)
//                            return SharedMediaFile.init(path: path, thumbnail: thumbnail, duration: $0.duration, type: $0.type)
//                        } else if ($0.type == .video && $0.thumbnail == nil) {
//                            return SharedMediaFile.init(path: path, thumbnail: nil, duration: $0.duration, type: $0.type)
//                        }
//
//                        return SharedMediaFile.init(path: path, thumbnail: nil, duration: $0.duration, type: $0.type)
//                    }
//                    latestMedia = sharedMediaFiles
//                    if(setInitialData) {
//                        initialMedia = latestMedia
//                    }
//                    eventSinkMedia?(toJson(data: latestMedia))
//                }
//            } else if url.fragment == "file" {
//                if let key = url.host?.components(separatedBy: "=").last,
//                   let json = userDefaults?.object(forKey: key) as? Data {
//                    let sharedArray = decode(data: json)
//                    let sharedMediaFiles: [SharedMediaFile] = sharedArray.compactMap{
//                        guard let path = getAbsolutePath(for: $0.path) else {
//                            return nil
//                        }
//                        return SharedMediaFile.init(path: $0.path, thumbnail: nil, duration: nil, type: $0.type)
//                    }
//                    latestMedia = sharedMediaFiles
//                    if(setInitialData) {
//                        initialMedia = latestMedia
//                    }
//                    eventSinkMedia?(toJson(data: latestMedia))
//                }
//            } else if url.fragment == "text" {
//                if let key = url.host?.components(separatedBy: "=").last,
//                   let sharedArray = userDefaults?.object(forKey: key) as? [String] {
//                    latestText =  sharedArray.joined(separator: ",")
//                    if(setInitialData) {
//                        initialText = latestText
//                    }
//                    eventSinkText?(latestText)
//                }
//            } else {
//                latestText = url.absoluteString
//                if(setInitialData) {
//                    initialText = latestText
//                }
//                eventSinkText?(latestText)
//            }
//            return true
        }
        latestMedia = nil
        return false
    }

    private func getAbsolutePath(for identifier: String) -> String? {
        if (identifier.starts(with: "file://") || identifier.starts(with: "/var/mobile/Media") || identifier.starts(with: "/private/var/mobile")) {
            return identifier.replacingOccurrences(of: "file://", with: "")
        }
        let phAsset = PHAsset.fetchAssets(withLocalIdentifiers: [identifier], options: .none).firstObject
        if(phAsset == nil) {
            return nil
        }
        let (url, _) = getFullSizeImageURLAndOrientation(for: phAsset!)
        return url
    }

    private func getFullSizeImageURLAndOrientation(for asset: PHAsset)-> (String?, Int) {
        var url: String? = nil
        var orientation: Int = 0
        let semaphore = DispatchSemaphore(value: 0)
        let options2 = PHContentEditingInputRequestOptions()
        options2.isNetworkAccessAllowed = true
        asset.requestContentEditingInput(with: options2){(input, info) in
            orientation = Int(input?.fullSizeImageOrientation ?? 0)
            url = input?.fullSizeImageURL?.path
            semaphore.signal()
        }
        semaphore.wait()
        return (url, orientation)
    }

    func getInitialSharedMedia(_ error: AutoreleasingUnsafeMutablePointer<FlutterError?>) -> SharedMedia? {
        let sharedMedia = initialMedia
        return sharedMedia
    }

    func recordSentMessage(_ media: SharedMedia?, error: AutoreleasingUnsafeMutablePointer<FlutterError?>) {
        // Create an INSendMessageIntent to donate an intent for a conversation with Juan Chavez.
        if let media = media {
            if #available(iOS 11.0, *) {
                let groupName = INSpeakableString(spokenPhrase: media.speakableGroupName ?? "Unknown Contact")
                let sendMessageIntent = INSendMessageIntent(recipients: nil,
                                                            content: nil,
                                                            speakableGroupName: groupName,
                                                            conversationIdentifier: media.conversationIdentifier,
                                                            serviceName: media.serviceName,
                                                            sender: nil)

                if #available(iOS 12.0, *) {
                    // Add the user's avatar to the intent.
                    if let imagePath = media.imageFilePath {
                        let imageUrl = URL(fileURLWithPath: imagePath)
                        let image = INImage.init(url: imageUrl)
                        sendMessageIntent.setImage(image, forParameterNamed: \.speakableGroupName)
                    }

                }

                // Donate the intent.
                let interaction = INInteraction(intent: sendMessageIntent, response: nil)
                interaction.donate(completion: { err in
                    if err != nil {
                        error.pointee = FlutterError.init(code: "NATIVE_ERR", message: "Error: donating insendmessage intent", details: nil)
                    } else {
                        print("Successfully dontated INSendMessageIntent")
                    }
                })
            }
        } else {
            error.pointee = FlutterError.init(code: "NATIVE_ERR", message: "Error: decoding SharedMedia", details: nil)
        }
    }

    public func resetInitialSharedMedia(_ error: AutoreleasingUnsafeMutablePointer<FlutterError?>) {
        initialMedia = nil
    }
}

extension URL {
    var queryDictionary: [String: String]? {
        guard let query = self.query else { return nil}

        var queryStrings = [String: String]()
        for pair in query.components(separatedBy: "&") {

            let key = pair.components(separatedBy: "=")[0]

            let value = pair
                .components(separatedBy:"=")[1]
                .replacingOccurrences(of: "+", with: " ")
                .removingPercentEncoding ?? ""

            queryStrings[key] = value
        }
        return queryStrings
    }
}
