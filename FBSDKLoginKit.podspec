# Use the --use-libraries switch when pushing or linting this podspec

Pod::Spec.new do |s|

  s.name         = 'FBSDKLoginKit'
  s.version      = '6.5.2'
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

  s.source       = { :git => 'https://github.com/facebook/facebook-ios-sdk.git',
                     :tag => "v#{s.version}"
                    }

  s.ios.weak_frameworks = 'Accounts', 'Social', 'Security', 'QuartzCore', 'CoreGraphics', 'UIKit', 'Foundation', 'AudioToolbox'
  s.tvos.weak_frameworks = 'AudioToolbox', 'CoreGraphics', 'Foundation', 'QuartzCore', 'Security', 'UIKit'

  s.requires_arc = true

  s.default_subspecs = 'Login'
  s.swift_version = '5.0'
  s.prefix_header_contents = '#define FBSDKCOCOAPODS'

  s.subspec 'Login' do |ss|
    ss.dependency 'FBSDKCoreKit', "~> #{s.version}"
    ss.exclude_files = 'FBSDKLoginKit/FBSDKLoginKit/include/**/*'
    ss.source_files   = 'FBSDKLoginKit/FBSDKLoginKit/**/*.{h,m}'
    ss.public_header_files = 'FBSDKLoginKit/FBSDKLoginKit/*.{h}'
  end

  s.subspec 'Swift' do |ss|
    ss.dependency 'FBSDKCoreKit/Swift', "~> #{s.version}"
    ss.dependency 'FBSDKLoginKit/Login'
    ss.exclude_files = 'FBSDKLoginKit/FBSDKLoginKit/Swift/Exports.swift'
    ss.source_files   = 'FBSDKLoginKit/FBSDKLoginKit/Swift/*.{swift}'
  end

end
