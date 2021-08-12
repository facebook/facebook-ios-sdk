# Use the --use-libraries switch when pushing or linting this podspec

Pod::Spec.new do |s|

  s.name         = 'LegacyGamingServices'
  s.version      = '11.1.0'
  s.summary      = 'The legacy Objective-C implementation of FBSDKGamingServicesKit that will be converted to Swift.'

  s.description  = <<-DESC
                   The legacy Objective-C implementation of FBSDKGamingServicesKit that will be converted to Swift.
                   This will not contain interfaces for new features written in Swift.
                   If you are looking for the FacebookGamingServices SDK please use `pod FacebookGamingServices`.
                   DESC

  s.homepage     = 'https://developers.facebook.com/docs/ios/'
  s.license      = { type: 'Facebook Platform License', file: 'LICENSE' }
  s.author       = 'Facebook'

  s.platform     = :ios
  s.ios.deployment_target = '9.0'

  s.swift_version = '5.0'

  s.source       = {
    git: 'https://github.com/facebook/facebook-ios-sdk.git',
    tag: "v#{s.version}"
  }

  s.weak_frameworks = 'Accounts', 'Social', 'Security', 'Foundation', 'CoreGraphics'

  s.requires_arc = true
  s.pod_target_xcconfig = {
    'GCC_PREPROCESSOR_DEFINITIONS': '$(inherited) FBSDKCOCOAPODS=1',
    'OTHER_SWIFT_FLAGS': '$(inherited) -Xcc -DFBSDKCOCOAPODS',
    'DEFINES_MODULE': 'YES',
  }

  s.source_files   = 'FBSDKGamingServicesKit/LegacyGamingServices/**/*.{h,m}'
  s.public_header_files = 'FBSDKGamingServicesKit/LegacyGamingServices/*.{h}'
  s.exclude_files = 'FBSDKGamingServicesKit/LegacyGamingServices/include/**/*'

  s.dependency 'FBSDKCoreKit_Basics', "~> #{s.version}"
  s.dependency 'FBSDKCoreKit', "~> #{s.version}"
end
