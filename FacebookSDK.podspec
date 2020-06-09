# If you've made changes to the SDK (such as file paths), consider using `pod lib lint` to lint locally and then using the :path option in your Podfile

Pod::Spec.new do |s|

  s.name         = 'FacebookSDK'
  s.version      = '7.0.1'
  s.summary      = 'Official Facebook SDK for iOS to access Facebook Platform'

  s.description  = <<-DESC
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
  s.tvos.deployment_target = '10.0'

  s.source       = { :git => 'https://github.com/facebook/facebook-ios-sdk.git',
                     :tag => "v#{s.version}" }

  s.ios.weak_frameworks = 'Accounts', 'Social', 'Security', 'QuartzCore', 'CoreGraphics', 'UIKit', 'Foundation', 'AudioToolbox', 'WebKit'
  s.tvos.weak_frameworks = 'Security', 'QuartzCore', 'CoreGraphics', 'UIKit', 'Foundation', 'AudioToolbox'

  s.requires_arc = true

  s.default_subspecs = 'CoreKit'

  s.subspec 'CoreKit' do |ss|
    ss.dependency 'FBSDKCoreKit', "~> #{s.version}"
  end
  s.subspec 'LoginKit' do |ss|
    ss.dependency 'FacebookSDK/CoreKit'
    ss.dependency 'FBSDKLoginKit', "~> #{s.version}"
  end
  s.subspec 'ShareKit' do |ss|
    ss.dependency 'FacebookSDK/CoreKit'
    ss.dependency 'FBSDKShareKit', "~> #{s.version}"
  end
  s.subspec 'TVOSKit' do |ss|
    ss.platform = :tvos
    ss.dependency 'FacebookSDK/ShareKit'
    ss.dependency 'FacebookSDK/LoginKit'
    ss.dependency 'FBSDKTVOSKit', "~> #{s.version}"
  end
end
