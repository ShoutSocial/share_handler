#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint share_handler_ios.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'share_handler_ios_models'
  s.version          = '0.0.9'
  s.summary          = 'Shared code for share_handler_ios plugin.'
  s.description      = <<-DESC
  Shared code for share_handler_ios plugin so main app and share extension targets can use it.
                       DESC
  s.homepage         = 'http://example.com'
  # s.license          = { :file => '../LICENSE' }
  s.author           = { 'Shout Social' => 'developer@shoutsocial.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.public_header_files = 'Classes/**/*.h'
  s.platform = :ios, '9.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'
end
