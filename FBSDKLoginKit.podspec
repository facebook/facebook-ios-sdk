# Use the --use-libraries switch when pushing or linting this podspec

Pod::Spec.new do |s|

  s.name         = 'FBSDKLoginKit'
  s.version      = '5.5.0'
  s.summary      = 'Official Facebook SDK for iOS to access Facebook Platform with features like Login, Share and Message Dialog, App Links, and Graph API'

  s.description  = <<-DESC
                   The Facebook SDK for iOS LoginKit framework provides:
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

  s.source       = { :git => 'https://github.com/facebook/facebook-objc-sdk.git',
                     :tag => "v#{s.version}"
                    }

  s.ios.weak_frameworks = 'Accounts', 'CoreLocation', 'Social', 'Security', 'QuartzCore', 'CoreGraphics', 'UIKit', 'Foundation', 'AudioToolbox'
  s.tvos.weak_frameworks = 'AudioToolbox', 'CoreGraphics', 'CoreLocation', 'Foundation', 'QuartzCore', 'Security', 'UIKit'

  s.requires_arc = true

  s.dependency 'FBSDKCoreKit', "~> 5.0"

  s.ios.source_files   = 'FBSDKLoginKit/FBSDKLoginKit/**/*.{h,m}'
  s.ios.public_header_files = 'FBSDKLoginKit/FBSDKLoginKit/*.{h}'
  s.tvos.source_files = 'FBSDKLoginKit/FBSDKLoginKit/FBSDKLoginConstants.{h,m}',
                        'FBSDKLoginKit/FBSDKLoginKit/FBSDKDeviceLoginCodeInfo.{h,m}',
                        'FBSDKLoginKit/FBSDKLoginKit/FBSDKDeviceLoginManager.{h,m}',
                        'FBSDKLoginKit/FBSDKLoginKit/FBSDKDeviceLoginManagerResult.{h,m}',
                        'FBSDKLoginKit/FBSDKLoginKit/Internal/FBSDKError.{h,m}',
                        'FBSDKLoginKit/FBSDKLoginKit/Internal/FBSDKDeviceLoginCodeInfo+Internal.h',
                        'FBSDKLoginKit/FBSDKLoginKit/Internal/FBSDKDeviceLoginError.{h,m}',
                        'FBSDKLoginKit/FBSDKLoginKit/Internal/FBSDKDeviceLoginManagerResult+Internal.h'
  s.tvos.public_header_files = 'FBSDKLoginKit/FBSDKLoginKit/FBSDKDeviceLoginCodeInfo.h',
                               'FBSDKLoginKit/FBSDKLoginKit/FBSDKDeviceLoginManager.h',
                               'FBSDKLoginKit/FBSDKLoginKit/FBSDKDeviceLoginManagerResult.h',
                               'FBSDKLoginKit/FBSDKLoginKit/FBSDKLoginConstants.h'

end
