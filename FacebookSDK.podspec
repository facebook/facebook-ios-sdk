# If you've made changes to the SDK (such as file paths), consider using `pod lib lint` to lint locally and then using the :path option in your Podfile

Pod::Spec.new do |s|

  s.name         = 'FacebookSDK'
  s.version      = '12.0.0'
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

  s.platform = :ios, '9.0'

  s.source       = { :http => "https://github.com/facebook/facebook-ios-sdk/releases/download/v#{s.version}/FacebookSDK_Static.zip" }

  s.ios.weak_frameworks = 'Accelerate', 'Accounts', 'Social', 'Security', 'QuartzCore', 'CoreGraphics', 'UIKit', 'Foundation', 'AudioToolbox', 'WebKit'
  s.tvos.weak_frameworks = 'Security', 'QuartzCore', 'CoreGraphics', 'UIKit', 'Foundation', 'AudioToolbox'

  s.swift_version = '5.0'

  s.pod_target_xcconfig = {
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]': 'arm64',
    'EXCLUDED_ARCHS[sdk=appletvsimulator*]' => 'arm64',
  }
  s.user_target_xcconfig = {
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]': 'arm64',
    'EXCLUDED_ARCHS[sdk=appletvsimulator*]' => 'arm64'
  }

  s.subspec 'Basics' do |ss|
    ss.platform = :ios, :tvos
    ss.ios.deployment_target = '9.0'

    ss.ios.vendored_framework = 'FBSDKCoreKit_Basics.framework'
    ss.tvos.vendored_framework = 'tv/FBSDKCoreKit_Basics.framework'
    ss.tvos.deployment_target = '10.0'
  end

  s.subspec 'AEMKit' do |ss|
    ss.ios.dependency 'FacebookSDK/Basics'
    ss.ios.vendored_framework = 'FBAEMKit.framework'
  end

  s.subspec 'CoreKit' do |ss|
    ss.ios.dependency 'FacebookSDK/AEMKit'
    ss.ios.dependency 'FacebookSDK/Basics'
    ss.ios.vendored_framework = 'FBSDKCoreKit.framework'

    ss.tvos.deployment_target = '10.0'
    ss.tvos.dependency 'FacebookSDK/Basics'
    ss.tvos.vendored_framework = 'tv/FBSDKCoreKit.framework'
  end

  s.subspec 'LoginKit' do |ss|
    ss.dependency 'FacebookSDK/CoreKit'
    ss.ios.vendored_framework = 'FBSDKLoginKit.framework'

    ss.tvos.deployment_target = '10.0'
    ss.tvos.vendored_framework = 'tv/FBSDKLoginKit.framework'
  end

  s.subspec 'ShareKit' do |ss|
    ss.dependency 'FacebookSDK/CoreKit'
    ss.ios.vendored_framework = 'FBSDKShareKit.framework'

    ss.tvos.deployment_target = '10.0'
    ss.tvos.vendored_framework = 'tv/FBSDKShareKit.framework'
  end

  s.subspec 'TVOSKit' do |ss|
    ss.platform = :tvos
    ss.tvos.deployment_target = '10.0'
    ss.dependency 'FacebookSDK/CoreKit'
    ss.dependency 'FacebookSDK/ShareKit'
    ss.dependency 'FacebookSDK/LoginKit'
    ss.vendored_framework = 'tv/FBSDKTVOSKit.framework'
  end
end
