# If you've made changes to the SDK (such as file paths), consider using `pod lib lint` to lint locally and then using the :path option in your Podfile

Pod::Spec.new do |s|

  s.name         = 'FacebookSDK'
  s.version      = '9.1.0'
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
  s.ios.deployment_target = '9.0'
  s.tvos.deployment_target = '10.0'

  s.source       = { :http => "https://github.com/facebook/facebook-ios-sdk/releases/download/v#{s.version}/FacebookSDK_Static.zip" }

  s.ios.weak_frameworks = 'Accounts', 'Social', 'Security', 'QuartzCore', 'CoreGraphics', 'UIKit', 'Foundation', 'AudioToolbox', 'WebKit'
  s.tvos.weak_frameworks = 'Security', 'QuartzCore', 'CoreGraphics', 'UIKit', 'Foundation', 'AudioToolbox'

  s.requires_arc = true
  s.swift_version = '5.0'

  s.default_subspecs = 'CoreKit'

  s.pod_target_xcconfig = {
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]': 'arm64',
    'EXCLUDED_ARCHS[sdk=appletvsimulator*]' => 'arm64'
  }
  s.user_target_xcconfig = {
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]': 'arm64',
    'EXCLUDED_ARCHS[sdk=appletvsimulator*]' => 'arm64'
  }

  s.subspec 'CoreKit' do |ss|
    ss.dependency 'FBSDKCoreKit', "~> #{s.version}"
  end
  s.subspec 'LoginKit' do |ss|
    ss.dependency 'FacebookSDK/CoreKit'
    ss.ios.vendored_framework = 'FBSDKLoginKit.framework'
    ss.tvos.vendored_framework = 'tv/FBSDKLoginKit.framework'
  end
  s.subspec 'ShareKit' do |ss|
    ss.dependency 'FacebookSDK/CoreKit'
    ss.ios.vendored_framework = 'FBSDKShareKit.framework'
    ss.tvos.vendored_framework = 'tv/FBSDKShareKit.framework'
  end
  s.subspec 'TVOSKit' do |ss|
    ss.platform = :tvos
    ss.dependency 'FacebookSDK/ShareKit'
    ss.dependency 'FacebookSDK/LoginKit'
    ss.vendored_framework = 'tv/FBSDKTVOSKit.framework'
  end
end
