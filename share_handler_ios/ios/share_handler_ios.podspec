#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint share_handler.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'share_handler_ios'
  s.version          = '0.0.14'
  s.summary          = 'iOS implementation of the share_handler plugin.'
  s.description      = <<-DESC
  iOS implementation of the share_handler plugin.
                       DESC
  s.homepage         = 'http://example.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Your Company' => 'email@example.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.public_header_files = 'Classes/**/*.h'
  s.dependency 'Flutter'
  s.dependency 'share_handler_ios_models'
  s.subspec 'share_handler_ios_models' do |ss|
    ss.source_files = './Models/Classes/**/*'
    ss.public_header_files = './Models/Classes/**/*.h'
  end
  s.platform = :ios, '9.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'
end
