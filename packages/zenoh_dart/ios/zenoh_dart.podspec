#
# CocoaPods spec for the zenoh_dart FFI plugin on iOS.
#
# The Zenoh C library is shipped as a prebuilt dynamic XCFramework. Build it with
# bash .claude/skills/zenoh-build-ios/build_zenoh_ios.sh <version> from the repository root and activate a version with
# bash .claude/skills/zenoh-activate-libs/copy_zenoh_libs.sh <version> ios, which copies it to ios/Frameworks/zenohc.xcframework.
#
Pod::Spec.new do |s|
  s.name             = 'zenoh_dart'
  s.version          = '0.2.1'
  s.summary          = 'Dart and Flutter FFI bindings for the Eclipse Zenoh middleware.'
  s.description      = <<-DESC
Dart and Flutter FFI bindings for Eclipse Zenoh. Bundles a prebuilt zenoh-c dynamic framework.
                       DESC
  s.homepage         = 'https://github.com/salimpia/zenoh_dart'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'M-PIA' => 'info@m-pia.dev' }
  s.source           = { :path => '.' }

  # No native sources of our own beyond a stub: everything lives in the vendored framework.
  s.source_files        = 'Classes/**/*'
  s.vendored_frameworks = 'Frameworks/zenohc.xcframework'
  s.preserve_paths      = 'Frameworks/zenohc.xcframework'

  s.dependency 'Flutter'
  s.platform = :ios, '13.0'

  s.frameworks = ['Security', 'SystemConfiguration']

  s.pod_target_xcconfig = {
    'DEFINES_MODULE' => 'YES',
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386',
  }
  s.swift_version = '5.0'
end
