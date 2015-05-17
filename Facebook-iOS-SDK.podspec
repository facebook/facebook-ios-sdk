# If you've made changes to the SDK (such as file paths), consider using `pod lib lint` to lint locally and then using the :path option in your Podfile

Pod::Spec.new do |s|

  s.name         = "Facebook-iOS-SDK"
  s.version      = "4.1.0"
  s.summary      = "Official Facebook SDK for iOS to access Facebook Platform with features like Login, Share and Message Dialog, App Links, and Graph API"

  s.description  = <<-DESC
                  (DEPRECATED: Use FBSDKCoreKit,FBSDKLoginKit, and FBSDKShareKit podspecs instead)
                   The Facebook SDK for iOS enables you to use Facebook's Platform such as:
                   * Facebook Login to easily sign in users.
                   * Sharing features like the Share or Message Dialog to grow your app.
                   * Simpler Graph API access to provide more social context.
                   DESC

  s.homepage     = "https://developers.facebook.com/docs/ios/"
  s.license      = { :type => "Facebook Platform License", :file => "LICENSE" }
  s.author       = 'Facebook'

  s.platform     = :ios, "7.0"

  s.source       = { :git => "https://github.com/facebook/facebook-ios-sdk.git",
                     :tag => "sdk-version-4.1.0"
                    }

  s.weak_frameworks = "Accounts", "CoreLocation", "Social", "Security", "QuartzCore", "CoreGraphics", "UIKit", "Foundation", "AudioToolbox"

  s.requires_arc = true

  s.dependency 'Bolts', '~> 1.1'

  s.subspec 'CoreKit' do |spec|
    spec.source_files   = "FBSDKCoreKit/FBSDKCoreKit/**/*.{h,m}"
    spec.exclude_files = "FBSDKCoreKit/FBSDKCoreKit/Internal/FBSDKDynamicFrameworkLoader.m"
    spec.public_header_files = "FBSDKCoreKit/FBSDKCoreKit/*.{h}"
    spec.header_dir = "FBSDKCoreKit"
    spec.subspec 'no-arc' do |sp|
      sp.source_files = "FBSDKCoreKit/FBSDKCoreKit/**/*.h","FBSDKCoreKit/FBSDKCoreKit/Internal/FBSDKDynamicFrameworkLoader.{h,m}"
      sp.requires_arc = false
    end
  end
  s.subspec 'LoginKit' do |spec|
    spec.source_files   = "FBSDKLoginKit/FBSDKLoginKit/**/*.{h,m}"
    spec.public_header_files = "FBSDKLoginKit/FBSDKLoginKit/*.{h}"
    spec.header_dir = "FBSDKLoginKit"
    spec.dependency 'Facebook-iOS-SDK/CoreKit'
  end
  s.subspec 'ShareKit' do |spec|
    spec.source_files   = "FBSDKShareKit/FBSDKShareKit/**/*.{h,m}"
    spec.public_header_files = "FBSDKShareKit/FBSDKShareKit/*.{h}"
    spec.header_dir = "FBSDKShareKit"
    spec.dependency 'Facebook-iOS-SDK/CoreKit'
  end

  s.deprecated = true
  s.deprecated_in_favor_of = 'FBSDKCoreKit'
end
