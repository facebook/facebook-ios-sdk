# If you've made changes to the SDK (such as file paths), consider using `pod lib lint` to lint locally and then using the :path option in your Podfile

Pod::Spec.new do |s|

  s.name         = "Facebook-iOS-SDK"
  s.version      = "4.35.0"
  s.summary      = "Official Facebook SDK for iOS to access Facebook Platform with features like Login, Share and Message Dialog, App Links, and Graph API"

  s.description  = <<-DESC
                   The Facebook SDK for iOS enables you to use Facebook's Platform such as:
                   * Facebook Login to easily sign in users.
                   * Sharing features like the Share or Message Dialog to grow your app.
                   * Simpler Graph API access to provide more social context.
                   DESC

  s.homepage     = "https://developers.facebook.com/docs/ios/"
  s.license      = { :type => "Facebook Platform License", :file => "FacebookSDKs-iOS-universal-4.35.0/iOS/LICENSE.txt" }
  s.author       = 'Facebook'

  s.platform     = :ios, :tvos
  s.ios.deployment_target = '8.0'
  s.tvos.deployment_target = '9.0'

  s.source       = { :http => 'https://origincache.facebook.com/developers/resources/?id=FacebookSDKs-iOS-universal-4.35.0.zip', :type => :zip }

  s.ios.weak_frameworks = 'Accounts', 'CoreLocation', 'Social', 'Security', 'QuartzCore', 'CoreGraphics', 'UIKit', 'Foundation', 'AudioToolbox', 'WebKit'
  s.tvos.weak_frameworks = 'CoreLocation', 'Security', 'QuartzCore', 'CoreGraphics', 'UIKit', 'Foundation', 'AudioToolbox'

  s.requires_arc = true

  s.dependency 'Bolts', '~> 1.7'

  s.subspec 'CoreKit' do |spec|
    spec.ios.source_files      = 'FacebookSDKs-iOS-universal-4.35.0/iOS/FBSDKCoreKit.framework/**/*.h'
    spec.ios.resources = 'FacebookSDKs-iOS-universal-4.35.0/iOS/FacebookSDKStrings.bundle'
    spec.ios.public_header_files = 'FacebookSDKs-iOS-universal-4.35.0/iOS/FBSDKCoreKit.framework/**/*.h'
    spec.ios.vendored_frameworks = 'FacebookSDKs-iOS-universal-4.35.0/iOS/FBSDKCoreKit.framework'
    spec.tvos.source_files      = 'FacebookSDKs-iOS-universal-4.35.0/tvOS/FBSDKCoreKit.framework/**/*.h'
    spec.tvos.resources = 'FacebookSDKs-iOS-universal-4.35.0/tvOS/FacebookSDKStrings.bundle'
    spec.tvos.public_header_files = 'FacebookSDKs-iOS-universal-4.35.0/tvOS/FBSDKCoreKit.framework/**/*.h'
    spec.tvos.vendored_frameworks = 'FacebookSDKs-iOS-universal-4.35.0/tvOS/FBSDKCoreKit.framework'
  end
  s.subspec 'LoginKit' do |spec|
    spec.ios.source_files      = 'FacebookSDKs-iOS-universal-4.35.0/iOS/FBSDKLoginKit.framework/**/*.h'
    spec.ios.public_header_files = 'FacebookSDKs-iOS-universal-4.35.0/iOS/FBSDKLoginKit.framework/**/*.h'
    spec.ios.vendored_frameworks = 'FacebookSDKs-iOS-universal-4.35.0/iOS/FBSDKLoginKit.framework'
    spec.tvos.source_files      = 'FacebookSDKs-iOS-universal-4.35.0/tvOS/FBSDKLoginKit.framework/**/*.h'
    spec.tvos.public_header_files = 'FacebookSDKs-iOS-universal-4.35.0/tvOS/FBSDKLoginKit.framework/**/*.h'
    spec.tvos.vendored_frameworks = 'FacebookSDKs-iOS-universal-4.35.0/tvOS/FBSDKLoginKit.framework'
    spec.dependency 'Facebook-iOS-SDK/CoreKit'
  end
  s.subspec 'ShareKit' do |spec|
    spec.ios.source_files      = 'FacebookSDKs-iOS-universal-4.35.0/iOS/FBSDKShareKit.framework/**/*.h'
    spec.ios.public_header_files = 'FacebookSDKs-iOS-universal-4.35.0/iOS/FBSDKShareKit.framework/**/*.h'
    spec.ios.vendored_frameworks = 'FacebookSDKs-iOS-universal-4.35.0/iOS/FBSDKShareKit.framework'
    spec.tvos.source_files      = 'FacebookSDKs-iOS-universal-4.35.0/tvOS/FBSDKShareKit.framework/**/*.h'
    spec.tvos.public_header_files = 'FacebookSDKs-iOS-universal-4.35.0/tvOS/FBSDKShareKit.framework/**/*.h'
    spec.tvos.vendored_frameworks = 'FacebookSDKs-iOS-universal-4.35.0/tvOS/FBSDKShareKit.framework'
    spec.dependency 'Facebook-iOS-SDK/CoreKit'
  end
  s.subspec 'TVOSKit' do |spec|
    spec.platform = :tvos
    spec.source_files      = 'FacebookSDKs-iOS-universal-4.35.0/tvOS/FBSDKTVOSKit.framework/**/*.h'
    spec.public_header_files = 'FacebookSDKs-iOS-universal-4.35.0/tvOS/FBSDKTVOSKit.framework/**/*.h'
    spec.vendored_frameworks = 'FacebookSDKs-iOS-universal-4.35.0/tvOS/FBSDKTVOSKit.framework'
    spec.dependency 'Facebook-iOS-SDK/ShareKit'
    spec.dependency 'Facebook-iOS-SDK/LoginKit'
  end
  s.subspec 'PlacesKit' do |spec|
    spec.platform = :ios
    spec.source_files      = 'FacebookSDKs-iOS-universal-4.35.0/iOS/FBSDKPlacesKit.framework/**/*.h'
    spec.public_header_files = 'FacebookSDKs-iOS-universal-4.35.0/iOS/FBSDKPlacesKit.framework/**/*.h'
    spec.vendored_frameworks = 'FacebookSDKs-iOS-universal-4.35.0/iOS/FBSDKPlacesKit.framework'
    spec.dependency 'Facebook-iOS-SDK/CoreKit'
  end
  s.subspec 'MarketingKit' do |spec|
    spec.platform = :ios
    spec.source_files      = 'FacebookSDKs-iOS-universal-4.35.0/iOS/FBSDKMarketingKit.framework/**/*.h'
    spec.public_header_files = 'FacebookSDKs-iOS-universal-4.35.0/iOS/FBSDKMarketingKit.framework/**/*.h'
    spec.vendored_frameworks = 'FacebookSDKs-iOS-universal-4.35.0/iOS/FBSDKMarketingKit.framework'
    spec.dependency 'Facebook-iOS-SDK/CoreKit'
  end
end
