# Use the --use-libraries switch when pushing or linting this podspec

Pod::Spec.new do |s|

  s.name         = "FBSDKLiveStreamingKit"
  s.version      = "SDK_VERSION_TO_RELEASE"
  s.summary      = "Official Facebook SDK for iOS to access Facebook Live Streaming"

  s.description  = <<-DESC
                   The Facebook SDK for iOS LiveStreamingKit framework provides:
                   * Live Streaming
                   DESC

  s.homepage     = "https://developers.facebook.com/docs/ios/"
  s.license      = { :type => "Facebook Platform License", :file => "LICENSE" }
  s.author       = 'Facebook'

  s.platform     = :ios, "9.0"
  s.ios.deployment_target = "7.0"

  s.source       = { :git => "https://github.com/facebook/facebook-ios-sdk.git",
                     :tag => "sdk-version-SDK_VERSION_TO_RELEASE"
                    }

  s.weak_frameworks = "Accounts", "CoreLocation", "Social", "Security", "Foundation"

  s.requires_arc = true

  s.source_files   = "FBSDKLiveStreamingKit/FBSDKLiveStreamingKit/**/*.{h,m}"
  s.public_header_files = "FBSDKLiveStreamingKit/FBSDKLiveStreamingKit/*.{h}"
  # Allow the weak linking to Bolts (see FBSDKAppLinkResolver.h) in Cocoapods 0.39.0
  s.pod_target_xcconfig = { 'CLANG_ALLOW_NON_MODULAR_INCLUDES_IN_FRAMEWORK_MODULES' => 'YES' }
  s.dependency 'FBSDKCoreKit'

end
