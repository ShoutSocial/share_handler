import UIKit
import Social
import MobileCoreServices
import Photos
import Intents
import share_handler_ios_models


class ShareViewController: SLComposeServiceViewController {
    static let hostAppBundleIdentifier = "com.aboutshout.shout1"
    static let groupAppBundleIdentifier = "group.\(ShareViewController.hostAppBundleIdentifier)"
    let sharedKey = "ShareKey"
    var sharedText: [String] = []
    let imageContentType = UTType.image.identifier
    let movieContentType = UTType.movie.identifier
    let textContentType = UTType.text.identifier
    let urlContentType = UTType.url.identifier
    let fileURLType = UTType.fileURL.identifier
    var sharedAttachments: [FLTSharedAttachment] = []
    lazy var userDefaults: UserDefaults = {
        return UserDefaults(suiteName: ShareViewController.groupAppBundleIdentifier)!
    }()
    
    
    override func isContentValid() -> Bool {
        return true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad();
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // This is called after the user selects Post. Do the upload of contentText and/or NSExtensionContext attachments.
        if let content = extensionContext!.inputItems[0] as? NSExtensionItem {
            if let contents = content.attachments {
                for (index, attachment) in (contents).enumerated() {
                    if attachment.hasItemConformingToTypeIdentifier(imageContentType) {
                        handleImages(content: content, attachment: attachment, index: index)
                    } else if attachment.hasItemConformingToTypeIdentifier(movieContentType) {
                        handleVideos(content: content, attachment: attachment, index: index)
                    } else if attachment.hasItemConformingToTypeIdentifier(fileURLType){
                        handleFiles(content: content, attachment: attachment, index: index)
                    } else if attachment.hasItemConformingToTypeIdentifier(urlContentType) {
                        handleUrl(content: content, attachment: attachment, index: index)
                    } else if attachment.hasItemConformingToTypeIdentifier(textContentType) {
                        handleText(content: content, attachment: attachment, index: index)
                    } else {
                        print("Attachment not handled with registered type identifiers: \(attachment.registeredTypeIdentifiers)")
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
            .containerURL(forSecurityApplicationGroupIdentifier: ShareViewController.groupAppBundleIdentifier)!
            .appendingPathComponent(fileName)
        return newFileUrl
    }
    
    private func handleText (content: NSExtensionItem, attachment: NSItemProvider, index: Int) {
        attachment.loadItem(forTypeIdentifier: textContentType, options: nil) { [weak self] data, error in
            
            if error == nil, let item = data as? String, let this = self {
                this.sharedText.append(item)
            } else {
                self?.dismissWithError()
            }
        }
    }
    
    private func handleUrl (content: NSExtensionItem, attachment: NSItemProvider, index: Int) {
        attachment.loadItem(forTypeIdentifier: urlContentType, options: nil) { [weak self] data, error in
            
            if error == nil, let item = data as? URL, let this = self {
                this.sharedText.append(item.absoluteString)
            } else {
                self?.dismissWithError()
            }
        }
    }
    
    private func handleImages (content: NSExtensionItem, attachment: NSItemProvider, index: Int) {
        attachment.loadItem(forTypeIdentifier: imageContentType, options: nil) { [weak self] data, error in
            
            
            if error != nil {
                self?.dismissWithError()
                return
            }
            
            var fileName: String?
            var imageData: Data?
            var sourceUrl: URL?
            if let url = data as? URL, let this = self {
                fileName = this.getFileName(from: url, type: .image)
                sourceUrl = url
            } else if let iData = data as? Data {
                fileName = UUID().uuidString + ".png"
                imageData = iData
            } else if let image = data as? UIImage {
                fileName = UUID().uuidString + ".png"
                imageData = image.pngData()
            }
            
            if let _fileName = fileName, let this = self {
                let newFileUrl = this.getNewFileUrl(fileName: _fileName)
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
                    copied = this.copyFile(at: _sourceUrl, to: newFileUrl)
                }
                
                if (copied) {
                    this.sharedAttachments.append(FLTSharedAttachment.init(path:  newFileUrl.absoluteString, type: .image))
                } else {
                    self?.dismissWithError()
                    return
                }
                
            } else {
                self?.dismissWithError()
                return
            }
        }
    }
    
    private func handleVideos (content: NSExtensionItem, attachment: NSItemProvider, index: Int) {
        attachment.loadItem(forTypeIdentifier: movieContentType, options: nil) { [weak self] data, error in
            
            if error == nil, let url = data as? URL, let this = self {
                
                // Always copy
                let fileName = this.getFileName(from: url, type: .video)
                let newFileUrl = this.getNewFileUrl(fileName: fileName)
                let copied = this.copyFile(at: url, to: newFileUrl)
                if(copied) {
                    this.sharedAttachments.append(FLTSharedAttachment.init(path:  newFileUrl.absoluteString, type: .video))
                }
            } else {
                self?.dismissWithError()
            }
        }
    }
    
    private func handleFiles (content: NSExtensionItem, attachment: NSItemProvider, index: Int) {
        attachment.loadItem(forTypeIdentifier: fileURLType, options: nil) { [weak self] data, error in
            
            if error == nil, let url = data as? URL, let this = self {
                
                // Always copy
                let fileName = this.getFileName(from :url, type: .file)
                let newFileUrl = this.getNewFileUrl(fileName: fileName)
                let copied = this.copyFile(at: url, to: newFileUrl)
                if (copied) {
                    this.sharedAttachments.append(FLTSharedAttachment.init(path:  newFileUrl.absoluteString, type: .file))
                }
            } else {
                self?.dismissWithError()
            }
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
        let url = URL(string: "ShareMedia://\(cShareHandlerUriHost)key=\(sharedKey)")
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
        
        let sharedMedia = FLTSharedMedia.init(attachments: sharedAttachments, conversationIdentifier: conversationIdentifier, content: sharedText.joined(separator: "\n"), speakableGroupName: speakableGroupName?.spokenPhrase, serviceName: serviceName, senderIdentifier: sender?.contactIdentifier ?? sender?.customIdentifier, imageFilePath: nil)
        
        let json = sharedMedia.toJson()
        
        userDefaults.set(json, forKey: self.sharedKey)
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
    
    func getExtension(from url: URL, type: FLTSharedAttachmentType) -> String {
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
    
    func getFileName(from url: URL, type: FLTSharedAttachmentType) -> String {
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
