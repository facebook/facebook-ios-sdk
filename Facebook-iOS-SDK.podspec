# If you've made changes to the SDK (such as file paths), consider using `pod lib lint` to lint locally and then using the :path option in your Podfile

Pod::Spec.new do |s|

  s.name         = 'Facebook-iOS-SDK'
  s.version      = '4.41.2'
  s.summary      = '(DEPRECATED: Use FacebookSDK instead) Official Facebook SDK for iOS to access Facebook Platform'

  s.description  = <<-DESC
                   (DEPRECATED: Use FacebookSDK podspec instead)
                   The Facebook SDK for iOS enables you to use Facebook's Platform such as:
                   * Facebook Login to easily sign in users.
                   * Sharing features like the Share or Message Dialog to grow your app.
                   * Simpler Graph API access to provide more social context.
                   DESC

  s.homepage     = 'https://developers.facebook.com/docs/ios/'
  s.license      = { :type => 'Facebook Platform License', :file => 'LICENSE' }
  s.author       = 'Facebook'

  s.platform     = :ios, :tvos
  s.ios.deployment_target = '8.0'
  s.tvos.deployment_target = '9.0'

  s.source       = { :git => 'https://github.com/facebook/facebook-objc-sdk.git',
                     :tag => "v#{s.version}" }

  s.ios.weak_frameworks = 'Accounts', 'CoreLocation', 'Social', 'Security', 'QuartzCore', 'CoreGraphics', 'UIKit', 'Foundation', 'AudioToolbox', 'WebKit'
  s.tvos.weak_frameworks = 'CoreLocation', 'Security', 'QuartzCore', 'CoreGraphics', 'UIKit', 'Foundation', 'AudioToolbox'

  s.requires_arc = true

  s.deprecated = true
  s.deprecated_in_favor_of = 'FacebookSDK'

  s.dependency 'Bolts', '~> 1.9'
  s.default_subspecs = 'CoreKit', 'MarketingKit'

  s.subspec 'CoreKit' do |ss|
    ss.dependency 'FBSDKCoreKit'
  end
  s.subspec 'LoginKit' do |ss|
    ss.dependency 'Facebook-iOS-SDK/CoreKit'
    ss.dependency 'FBSDKLoginKit'
  end
  s.subspec 'ShareKit' do |ss|
    ss.dependency 'Facebook-iOS-SDK/CoreKit'
    ss.dependency 'FBSDKShareKit'
  end
  s.subspec 'TVOSKit' do |ss|
    ss.platform = :tvos
    ss.dependency 'Facebook-iOS-SDK/ShareKit'
    ss.dependency 'Facebook-iOS-SDK/LoginKit'
    ss.dependency 'FBSDKTVOSKit'
  end
  s.subspec 'PlacesKit' do |ss|
    ss.platform = :ios
    ss.dependency 'Facebook-iOS-SDK/CoreKit'
    ss.dependency 'FBSDKPlacesKit'
  end
  s.subspec 'MarketingKit' do |ss|
    ss.platform = :ios
    ss.dependency 'Facebook-iOS-SDK/CoreKit'
    ss.dependency 'FBSDKMarketingKit'
  end
end
