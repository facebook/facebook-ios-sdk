# Use the --use-libraries switch when pushing or linting this podspec

Pod::Spec.new do |s|

  s.name         = 'FBSDKShareKit'
  s.version      = '7.1.1'
  s.summary      = 'Official Facebook SDK for iOS to access Facebook Platform Sharing Features'

  s.description  = <<-DESC
                   The Facebook SDK for iOS ShareKit framework provides:
                   * Share content with Share Dialog and Message Dialog.
                   * Send Game Requests or App Invites to grow your app.
                   * Publish content and open graph stories with the Graph API
                   DESC

  s.homepage     = 'https://developers.facebook.com/docs/ios/'
  s.license      = {
    type: 'Facebook Platform License',
    file: 'LICENSE'
  }
  s.author       = 'Facebook'

  s.platform     = :ios, :tvos
  s.ios.deployment_target = '8.0'
  s.tvos.deployment_target = '10.0'

  s.source       = {
    git: 'https://github.com/facebook/facebook-ios-sdk.git',
    tag: "v#{s.version}"
  }

  s.ios.weak_frameworks = 'Accounts', 'AudioToolbox', 'CoreGraphics', 'Foundation', 'QuartzCore', 'Security', 'Social', 'UIKit'
  s.tvos.weak_frameworks = 'AudioToolbox', 'CoreGraphics', 'Foundation', 'QuartzCore', 'Security', 'UIKit'

  s.requires_arc = true

  s.default_subspecs = 'Share'
  s.swift_version = '5.0'

  s.header_dir = 'FBSDKShareKit'
  s.prefix_header_contents = '#define FBSDKCOCOAPODS'

  s.subspec 'Share' do |ss|
    ss.dependency 'FBSDKCoreKit', "~> #{s.version}"

    ss.exclude_files = 'FBSDKShareKit/FBSDKShareKit/include/**/*',
                       'FBSDKShareKit/FBSDKShareKit/Swift/Exports.swift'
    ss.public_header_files = 'FBSDKShareKit/FBSDKShareKit/*.{h}'
    ss.source_files = 'FBSDKShareKit/FBSDKShareKit/**/*.{h,m,swift}'
  end
end
