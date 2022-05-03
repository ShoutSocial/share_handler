#import "ShareHandlerIosPlugin.h"
#if __has_include(<share_handler_ios/share_handler_ios-Swift.h>)
#import <share_handler_ios/share_handler_ios-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "share_handler_ios-Swift.h"
#endif

@implementation ShareHandlerIosPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftShareHandlerIosPlugin registerWithRegistrar:registrar];
}
@end
