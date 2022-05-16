import UIKit
import Social
import MobileCoreServices
import Photos
import Intents
import share_handler_ios_models


class ShareViewController: SLComposeServiceViewController {
    // TODO: IMPORTANT: This should be your host app bundle identifier
    static var hostAppBundleIdentifier = ""
    static var appGroupId = ""
    let sharedKey = "ShareKey"
    var sharedText: [String] = []
    let imageContentType = UTType.image.identifier
    let movieContentType = UTType.movie.identifier
    let textContentType = UTType.text.identifier
    let urlContentType = UTType.url.identifier
    let fileURLType = UTType.fileURL.identifier
    var sharedAttachments: [SharedAttachment] = []
    lazy var userDefaults: UserDefaults = {
        return UserDefaults(suiteName: ShareViewController.appGroupId)!
    }()
    
    
    override func isContentValid() -> Bool {
        return true
    }
    
    private func loadIds() {
            // loading Share extension App Id
            let shareExtensionAppBundleIdentifier = Bundle.main.bundleIdentifier!;


            // convert ShareExtension id to host app id
            // By default it is everything before the last "."
            // For example: com.test.ShareExtension -> com.test
            let lastIndexOfPoint = shareExtensionAppBundleIdentifier.lastIndex(of: ".");
        ShareViewController.hostAppBundleIdentifier = String(shareExtensionAppBundleIdentifier[..<lastIndexOfPoint!]);

            // loading custom AppGroupId from Build Settings or use group.<hostAppBundleIdentifier>
        ShareViewController.appGroupId = (Bundle.main.object(forInfoDictionaryKey: "AppGroupId") as? String) ?? "group.\(ShareViewController.hostAppBundleIdentifier)";
        }
    
    override func viewDidLoad() {
        super.viewDidLoad();
        
        // load group and app id from build info
                loadIds();
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // This is called after the user selects Post. Do the upload of contentText and/or NSExtensionContext attachments.
        Task {
            await handleInputItems()
        }
    }
    
    func handleInputItems() async {
        if let content = extensionContext!.inputItems[0] as? NSExtensionItem {
            if let contents = content.attachments {
                for (index, attachment) in (contents).enumerated() {
                    do {
                        if attachment.hasItemConformingToTypeIdentifier(imageContentType) {
                            try await handleImages(content: content, attachment: attachment, index: index)
                        } else if attachment.hasItemConformingToTypeIdentifier(movieContentType) {
                            try await handleVideos(content: content, attachment: attachment, index: index)
                        } else if attachment.hasItemConformingToTypeIdentifier(fileURLType){
                            try await handleFiles(content: content, attachment: attachment, index: index)
                        } else if attachment.hasItemConformingToTypeIdentifier(urlContentType) {
                            try await handleUrl(content: content, attachment: attachment, index: index)
                        } else if attachment.hasItemConformingToTypeIdentifier(textContentType) {
                            try await handleText(content: content, attachment: attachment, index: index)
                        } else {
                            print("Attachment not handled with registered type identifiers: \(attachment.registeredTypeIdentifiers)")
                        }
                    } catch {
                        self.dismissWithError()
                    }
                    
                }
            }
            redirectToHostApp()
        }
    }
    
    override func didSelectPost() {
        print("didSelectPost");
    }
    
    override func configurationItems() -> [Any]! {
        // To add configuration options via table cells at the bottom of the sheet, return an array of SLComposeSheetConfigurationItem here.
        return []
    }
    
    private func getNewFileUrl(fileName: String) -> URL {
        let newFileUrl = FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: ShareViewController.appGroupId)!
            .appendingPathComponent(fileName)
        return newFileUrl
    }
    
    private func handleText (content: NSExtensionItem, attachment: NSItemProvider, index: Int) async throws {
        let data = try await attachment.loadItem(forTypeIdentifier: textContentType, options: nil)
        
        if let item = data as? String {
            sharedText.append(item)
        } else {
            dismissWithError()
        }
        
    }
    
    private func handleUrl (content: NSExtensionItem, attachment: NSItemProvider, index: Int) async throws {
        let data = try await attachment.loadItem(forTypeIdentifier: urlContentType, options: nil)
        
            if let item = data as? URL {
                sharedText.append(item.absoluteString)
            } else {
                dismissWithError()
            }
        
    }
    
    private func handleImages (content: NSExtensionItem, attachment: NSItemProvider, index: Int) async throws {
        let data = try await attachment.loadItem(forTypeIdentifier: imageContentType, options: nil)
            
        var fileName: String?
        var imageData: Data?
        var sourceUrl: URL?
        if let url = data as? URL {
            fileName = getFileName(from: url, type: .image)
            sourceUrl = url
        } else if let iData = data as? Data {
            fileName = UUID().uuidString + ".png"
            imageData = iData
        } else if let image = data as? UIImage {
            fileName = UUID().uuidString + ".png"
            imageData = image.pngData()
        }
        
        if let _fileName = fileName {
            let newFileUrl = getNewFileUrl(fileName: _fileName)
            do {
                if FileManager.default.fileExists(atPath: newFileUrl.path) {
                    try FileManager.default.removeItem(at: newFileUrl)
                }
            } catch {
                print("Error removing item")
            }
            
            
            var copied: Bool = false
            if let _data = imageData {
                copied = FileManager.default.createFile(atPath: newFileUrl.path, contents: _data)
            } else if let _sourceUrl = sourceUrl {
                copied = copyFile(at: _sourceUrl, to: newFileUrl)
            }
            
            if (copied) {
                sharedAttachments.append(SharedAttachment.init(path:  newFileUrl.absoluteString, type: .image))
            } else {
                dismissWithError()
                return
            }
            
        } else {
            dismissWithError()
            return
        }
        
    }
    
    private func handleVideos (content: NSExtensionItem, attachment: NSItemProvider, index: Int) async throws {
        let data = try await attachment.loadItem(forTypeIdentifier: movieContentType, options: nil)
         
            
        if let url = data as? URL {
            
            // Always copy
            let fileName = getFileName(from: url, type: .video)
            let newFileUrl = getNewFileUrl(fileName: fileName)
            let copied = copyFile(at: url, to: newFileUrl)
            if(copied) {
                sharedAttachments.append(SharedAttachment.init(path:  newFileUrl.absoluteString, type: .video))
            }
        } else {
            dismissWithError()
        }
        
    }
    
    private func handleFiles (content: NSExtensionItem, attachment: NSItemProvider, index: Int) async throws {
        let data = try await attachment.loadItem(forTypeIdentifier: fileURLType, options: nil)
         
        if let url = data as? URL {
            
            // Always copy
            let fileName = getFileName(from :url, type: .file)
            let newFileUrl = getNewFileUrl(fileName: fileName)
            let copied = copyFile(at: url, to: newFileUrl)
            if (copied) {
                sharedAttachments.append(SharedAttachment.init(path:  newFileUrl.absoluteString, type: .file))
            }
        } else {
            dismissWithError()
        }
        
    }
    
    private func dismissWithError() {
        print("[ERROR] Error loading data!")
        let alert = UIAlertController(title: "Error", message: "Error loading data", preferredStyle: .alert)
        
        let action = UIAlertAction(title: "Error", style: .cancel) { _ in
            self.dismiss(animated: true, completion: nil)
        }
        
        alert.addAction(action)
        present(alert, animated: true, completion: nil)
        extensionContext!.completeRequest(returningItems: [], completionHandler: nil)
    }
    
    private func redirectToHostApp() {
        // ids may not loaded yet so we need loadIds here too
        loadIds();
        let url = URL(string: "ShareMedia-\(ShareViewController.hostAppBundleIdentifier)://\(ShareViewController.hostAppBundleIdentifier)?key=\(sharedKey)")
        var responder = self as UIResponder?
        let selectorOpenURL = sel_registerName("openURL:")
        
        let intent = self.extensionContext?.intent as? INSendMessageIntent
        
        let conversationIdentifier = intent?.conversationIdentifier
//        let content = intent?.content
//        let outgoingMessageType = intent?.outgoingMessageType //INOutgoingMessageType.unknown/text/audio
//        let recipients = intent?.recipients
        let sender = intent?.sender
        let serviceName = intent?.serviceName
        let speakableGroupName = intent?.speakableGroupName
        
        let sharedMedia = SharedMedia.init(attachments: sharedAttachments, conversationIdentifier: conversationIdentifier, content: sharedText.joined(separator: "\n"), speakableGroupName: speakableGroupName?.spokenPhrase, serviceName: serviceName, senderIdentifier: sender?.contactIdentifier ?? sender?.customIdentifier, imageFilePath: nil)
        
        let json = sharedMedia.toJson()
        
        userDefaults.set(json, forKey: sharedKey)
        userDefaults.synchronize()
        
        while (responder != nil) {
            if (responder?.responds(to: selectorOpenURL))! {
                let _ = responder?.perform(selectorOpenURL, with: url)
            }
            responder = responder!.next
        }
        extensionContext!.completeRequest(returningItems: [], completionHandler: nil)
    }
    
    enum RedirectType {
        case media
        case text
        case file
    }
    
    func getExtension(from url: URL, type: SharedAttachmentType) -> String {
        let parts = url.lastPathComponent.components(separatedBy: ".")
        var ex: String? = nil
        if (parts.count > 1) {
            ex = parts.last
        }
        
        if (ex == nil) {
            switch type {
            case .image:
                ex = "PNG"
            case .video:
                ex = "MP4"
            case .file:
                ex = "TXT"
            default:
                ex = ""
            }
        }
        return ex ?? "Unknown"
    }
    
    func getFileName(from url: URL, type: SharedAttachmentType) -> String {
        var name = url.lastPathComponent
        
        if (name.isEmpty) {
            name = UUID().uuidString + "." + getExtension(from: url, type: type)
        }
        
        return name
    }
    
    func copyFile(at srcURL: URL, to dstURL: URL) -> Bool {
        do {
            if FileManager.default.fileExists(atPath: dstURL.path) {
                try FileManager.default.removeItem(at: dstURL)
            }
            try FileManager.default.copyItem(at: srcURL, to: dstURL)
        } catch (let error) {
            print("Cannot copy item at \(srcURL) to \(dstURL): \(error)")
            return false
        }
        return true
    }
    
    //    private func getSharedMediaFile(forVideo: URL) -> SharedMediaFile? {
    //        let asset = AVAsset(url: forVideo)
    //        let duration = (CMTimeGetSeconds(asset.duration) * 1000).rounded()
    //        let thumbnailPath = getThumbnailPath(for: forVideo)
    //
    //        if FileManager.default.fileExists(atPath: thumbnailPath.path) {
    //            return SharedMediaFile(path: forVideo.absoluteString, thumbnail: thumbnailPath.absoluteString, duration: duration, type: .video)
    //        }
    //
    //        var saved = false
    //        let assetImgGenerate = AVAssetImageGenerator(asset: asset)
    //        assetImgGenerate.appliesPreferredTrackTransform = true
    //        //        let scale = UIScreen.main.scale
    //        assetImgGenerate.maximumSize =  CGSize(width: 360, height: 360)
    //        do {
    //            let img = try assetImgGenerate.copyCGImage(at: CMTimeMakeWithSeconds(600, preferredTimescale: Int32(1.0)), actualTime: nil)
    //            try UIImage.pngData(UIImage(cgImage: img))()?.write(to: thumbnailPath)
    //            saved = true
    //        } catch {
    //            saved = false
    //        }
    //
    //        return saved ? SharedMediaFile(path: forVideo.absoluteString, thumbnail: thumbnailPath.absoluteString, duration: duration, type: .video) : nil
    //
    //    }
    
    //    private func getThumbnailPath(for url: URL) -> URL {
    //        let fileName = Data(url.lastPathComponent.utf8).base64EncodedString().replacingOccurrences(of: "==", with: "")
    //        let path = FileManager.default
    //            .containerURL(forSecurityApplicationGroupIdentifier: "group.\(hostAppBundleIdentifier)")!
    //            .appendingPathComponent("\(fileName).jpg")
    //        return path
    //    }
    
    
}

//extension Array {
//    subscript (safe index: UInt) -> Element? {
//        return Int(index) < count ? self[Int(index)] : nil
//    }
//}
