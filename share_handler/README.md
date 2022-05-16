# Share Handler plugin for Flutter

A Flutter plugin for iOS and Android to handle incoming shared text/media, as well as add share to suggestions/shortcuts.

## Installation

First, add `share_handler` as a [dependency in your pubspec.yaml file](https://flutter.dev/using-packages/).

### iOS

1. Add the following to `<project root>/ios/Runner/Info.plist`. It registers your app to open via a deep link that will be launched from the Share Extension. Also, for sharing photos, you will need access to the photo library.
```xml
<!-- Add for share_handler start -->
	<!-- The 'NSUserActivityTypes' key is only needed if you plan to use the recordSentMessage API allowing for conversations to show up as direct share suggestions -->
	<key>NSUserActivityTypes</key>
	<array>
		<string>INSendMessageIntent</string>
	</array>
	<key>CFBundleURLTypes</key>
	<array>
		<dict>
			<key>CFBundleTypeRole</key>
			<string>Editor</string>
			<key>CFBundleURLSchemes</key>
			<array>
				<string>ShareMedia-$(PRODUCT_BUNDLE_IDENTIFIER)</string>
			</array>
		</dict>
		<dict/>
	</array>

  <key>NSPhotoLibraryUsageDescription</key>
	<string>Photos can be shared to and used in this app</string>
	<!-- Add for share_handler end -->
```
2. Create Share Extension
	- In Xcode, go to the menu and select File->New->Target and choose "Share Extension"
	- Give it the name "ShareExtension" and save
3. Make the following edits to `<project root>/ios/ShareExtension/Info.plist`.
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<!-- Add if you want custom group id rather than default. Set it in Build Settings -> User-Defined -->
	<key>AppGroupId</key>
  <string>$(CUSTOM_GROUP_ID)</string>
	
	<key>CFBundleVersion</key>
	<string>$(FLUTTER_BUILD_NUMBER)</string>
	<key>NSExtension</key>
	<dict>
		<key>NSExtensionAttributes</key>
		<dict>
			<!-- Add supported message intent if you support sharing to a specific conversation - start -->
			<key>IntentsSupported</key>
			<array>
				<string>INSendMessageIntent</string>
			</array>
			<!-- Add supported message intent if you support sharing to a specific conversation (registered via the recordSentMessage api call) - end -->
			<key>NSExtensionActivationRule</key>
			<!-- Comment or delete the TRUEPREDICATE NSExtensionActivationRule that only works in development mode -->
			<!-- <string>TRUEPREDICATE</string> -->
			<!-- Add a new NSExtensionActivationRule. The rule below will allow sharing one or more file of any type, url, or text content, You can modify these rules to your liking for which types of share content, as well as how many your app can handle -->
			<string>SUBQUERY ( 
					extensionItems, 
					$extensionItem, 
					SUBQUERY ( 
								$extensionItem.attachments, 
								$attachment, 
										( 
											ANY $attachment.registeredTypeIdentifiers UTI-CONFORMS-TO "public.file-url" 
										|| ANY $attachment.registeredTypeIdentifiers UTI-CONFORMS-TO "public.image" 
										|| ANY $attachment.registeredTypeIdentifiers UTI-CONFORMS-TO "public.text" 
										|| ANY $attachment.registeredTypeIdentifiers UTI-CONFORMS-TO "public.movie" 
										|| ANY $attachment.registeredTypeIdentifiers UTI-CONFORMS-TO "public.url" 
										) 
									).@count > 0
							).@count > 0
			</string>
			<key>PHSupportedMediaTypes</key>
			<array>
				<string></string>
				<string>Video</string>
				<string>Image</string>
			</array>
		</dict>
		<key>NSExtensionMainStoryboard</key>
		<string>MainInterface</string>
		<key>NSExtensionPointIdentifier</key>
		<string>com.apple.share-services</string>
	</dict>
</dict>
</plist>
```
4. Add a group identifier to both the Runner and ShareExtension Targets
	- In Xcode, select Runner -> Targets -> Runner -> Signing & Capabilities
	- Click the '+' button and select 'App Groups'
	- Add a new group (default is your bundle identifier prefixed by 'group.'. ex. 'group.com.shoutsocial')
	- Repeat those 3 steps inside of the 'ShareExtension' target adding/selecting the same group id
5. (Optional) If you made a custom group identifier that isn't your bundle identifier prefixed by 'group.', make sure to add a custom build setting variable that is referenced in your shareExtension's info.plist file.
	- Go to Targets -> ShareExtension -> Build Settings
	- Click the '+' icon and select 'Add User-Defined Setting'
	- Give it the key 'CUSTOM_GROUP_ID' and the value of the app group identifier that you gave to both targets in the previous step
6. Add the following code inside `<project root>/ios/Podfile` within the `target 'Runner' do` block
```ruby
target 'Runner' do
  use_frameworks!
  use_modular_headers!

  flutter_install_all_ios_pods File.dirname(File.realpath(__FILE__))

  # share_handler addition start
  target 'Share Extension' do
    inherit! :search_paths
    pod "share_handler_ios_models", :path => ".symlinks/plugins/share_handler_ios/ios/Models"
  end
  # share_handler addition end
end
```
7. In Xcode, replace the contents of ShareExtension/ShareViewController.swift with the following code. The share extension doesn't launch a UI of its own, instead it serializes the shared content/media and saves it to the groups shared preferences, then opens a deep link into the full app so your flutter/dart code can then read the serialized data and handle it accordingly.
    
    
    
	import UIKit
    import Social
    import MobileCoreServices
    import Photos
    import Intents
    import share_handler_ios_models
	
    class ShareViewController: SLComposeServiceViewController {
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
                // By default it is remove last part of id after last point
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
    }
    

### Android
1. Edit your Android Manifest file, located in `<project root>/android/app/src/main/AndroidManifest.xml` and add/uncomment the intent filters and meta data that you want to support:
```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
.....
 >
 <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>

  <application
        android:name="io.flutter.app.FlutterApplication"
        ...
        >

    <activity
            android:name=".MainActivity"
            android:launchMode="singleTop"
            android:theme="@style/LaunchTheme"
            android:configChanges="orientation|keyboardHidden|keyboard|screenSize|locale|layoutDirection|fontScale|screenLayout|density|uiMode"
            android:hardwareAccelerated="true"
            android:windowSoftInputMode="adjustResize">

             <!--TODO: Add this filter if you want to handle shared text-->
            <intent-filter>
                <action android:name="android.intent.action.SEND" />
                <category android:name="android.intent.category.DEFAULT" />
                <data android:mimeType="text/*" />
            </intent-filter>

            <!--TODO: Add this filter if you want to handle shared images-->
            <intent-filter>
                <action android:name="android.intent.action.SEND" />
                <category android:name="android.intent.category.DEFAULT" />
                <data android:mimeType="image/*" />
            </intent-filter>

            <intent-filter>
                <action android:name="android.intent.action.SEND_MULTIPLE" />
                <category android:name="android.intent.category.DEFAULT" />
                <data android:mimeType="image/*" />
            </intent-filter>

            <!--TODO: Add this filter if you want to handle shared videos-->
            <intent-filter>
                <action android:name="android.intent.action.SEND" />
                <category android:name="android.intent.category.DEFAULT" />
                <data android:mimeType="video/*" />
            </intent-filter>
            <intent-filter>
                <action android:name="android.intent.action.SEND_MULTIPLE" />
                <category android:name="android.intent.category.DEFAULT" />
                <data android:mimeType="video/*" />
            </intent-filter>

            <!--TODO: Add this filter if you want to handle any type of file-->
            <intent-filter>
                <action android:name="android.intent.action.SEND" />
                <category android:name="android.intent.category.DEFAULT" />
                <data android:mimeType="*/*" />
            </intent-filter>
            <intent-filter>
                <action android:name="android.intent.action.SEND_MULTIPLE" />
                <category android:name="android.intent.category.DEFAULT" />
                <data android:mimeType="*/*" />
            </intent-filter>

            <!-- TODO: (Optional) Add these meta-data tags if you want to support sharing to a specific target/conversation/shortcut (via the recordSentMessage api) -->
            <meta-data
                android:name="android.service.chooser.chooser_target_service"
                android:value="androidx.sharetarget.ChooserTargetServiceCompat" />
            <meta-data
                android:name="android.app.shortcuts"
                android:resource="@xml/share_targets" />
      </activity>

  </application>
</manifest>
```
2. (Optional) If you want to prevent incoming shares from opening a new activity each time, add the attribute `android:launchMode="singleTask"` to your MainActivity intent inside your AndroidManifest.xml file.
3. (Optional) Add required file to support share suggestions/shortcuts in to your app.
	- Create the file `<project root>/android/app/src/main/res/xml/share_targets.xml` with the following contents, replacing `{your.package.identifier}` with your package identifier (ex. con.shoutsocial.share_handler_android_example):
```xml
<?xml version="1.0" encoding="utf-8"?>
<shortcuts xmlns:android="http://schemas.android.com/apk/res/android">
    <share-target android:targetClass="{your.package.identifier}.MainActivity">
        <data android:mimeType="*/*" />
        <category android:name="{your.package.identifier}.dynamic_share_target" />
    </share-target>
</shortcuts>
```

## Example

```dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'dart:async';

import 'package:share_handler_platform_interface/messages.dart';
import 'package:share_handler_platform_interface/share_handler_platform_interface.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  SharedMedia? media;

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    final handler = ShareHandlerPlatform.instance;
    media = await handler.getInitialSharedMedia();

    handler.sharedMediaStream.listen((SharedMedia media) {
      if (!mounted) return;
      setState(() {
        this.media = media;
      });
    });
    if (!mounted) return;

    setState(() {
      // _platformVersion = platformVersion;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Share Handler'),
        ),
        body: Center(
          child: ListView(
            children: <Widget>[
              Text("Shared to conversation identifier: ${media?.conversationIdentifier}"),
              const SizedBox(height: 10),
              Text("Shared text: ${media?.content}"),
              const SizedBox(height: 10),
              Text("Shared files: ${media?.attachments?.length}"),
              ...(media?.attachments ?? []).map((attachment) {
                final _path = attachment?.path;
                if (_path != null && attachment?.type == SharedAttachmentType.image) {
                  return Column(
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          ShareHandlerPlatform.instance.recordSentMessage(
                            conversationIdentifier: "custom-conversation-identifier",
                            conversationName: "John Doe",
                            conversationImage: File(_path),
                            serviceName: "custom-service-name",
                          );
                        },
                        child: const Text("Record message"),
                      ),
                      const SizedBox(height: 10),
                      Image.file(File(_path)),
                    ],
                  );
                } else {
                  return Text("${attachment?.type} Attachment: ${attachment?.path}");
                }
              }),
            ],
          ),
        ),
      ),
    );
  }
}
```
