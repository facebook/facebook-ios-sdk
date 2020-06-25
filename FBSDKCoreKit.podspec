# Use the --use-libraries switch when pushing or linting this podspec

Pod::Spec.new do |s|

  s.name         = 'FBSDKCoreKit'
  s.version      = '7.1.1'
  s.summary      = 'Official Facebook SDK for iOS to access Facebook Platform core features'

  s.description  = <<-DESC
                   The Facebook SDK for iOS CoreKit framework provides:
                   * App Events (for App Analytics)
                   * Graph API Access and Error Recovery
                   * Working with Access Tokens and User Profiles
                   DESC

  s.homepage     = 'https://developers.facebook.com/docs/ios/'
  s.license      = { type: 'Facebook Platform License', file: 'LICENSE' }
  s.author       = 'Facebook'

  s.platform     = :ios, :tvos
  s.ios.deployment_target = '8.0'
  s.tvos.deployment_target = '10.0'

  s.source       = {
    git: 'https://github.com/facebook/facebook-ios-sdk.git',
    tag: "v#{s.version}"
  }

  s.ios.weak_frameworks = 'Accelerate', 'Accounts', 'Social', 'Security', 'QuartzCore', 'CoreGraphics', 'UIKit', 'Foundation', 'AudioToolbox'
  s.tvos.weak_frameworks = 'CoreLocation', 'Security', 'QuartzCore', 'CoreGraphics', 'UIKit', 'Foundation', 'AudioToolbox'

  # This excludes `FBSDKCoreKit/FBSDKCoreKit/Internal_NoARC/` folder, as that folder includes only `no-arc` files.
  s.requires_arc = ['FBSDKCoreKit/FBSDKCoreKit/*',
                    'FBSDKCoreKit/FBSDKCoreKit/AppEvents/**/*',
                    'FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*',
                    'FBSDKCoreKit/FBSDKCoreKit/Basics/**/*',
                    'FBSDKCoreKit/FBSDKCoreKit/GraphAPI/*',
                    'FBSDKCoreKit/FBSDKCoreKit/Internal/**/*']

  s.default_subspecs = 'Core', 'Basics'
  s.swift_version = '5.0'
  s.pod_target_xcconfig = {
    'GCC_PREPROCESSOR_DEFINITIONS': '$(inherited) FBSDKCOCOAPODS=1',
    'DEFINES_MODULE': 'YES'
  }
  s.user_target_xcconfig = {'GCC_PREPROCESSOR_DEFINITIONS': '$(inherited) FBSDKCOCOAPODS=1' }
  s.library = 'c++', 'stdc++'

  s.subspec 'Basics' do |ss|
    ss.source_files = 'FBSDKCoreKit/FBSDKCoreKit/Basics/*.{h,m}',
                      'FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.{h,m}'
    ss.public_header_files = 'FBSDKCoreKit/FBSDKCoreKit/Basics/Internal/**/*.h',
                             'FBSDKCoreKit/FBSDKCoreKit/Basics/Instrument/**/*.h',
                             'FBSDKCoreKit/FBSDKCoreKit/Basics/*.h'
    ss.private_header_files = 'FBSDKCoreKit/FBSDKCoreKit/Basics/Internal/**/*.h',
                              'FBSDKCoreKit/FBSDKCoreKit/Basics/Instrument/**/*.h'
    ss.library = 'z'
  end

  s.subspec 'Core' do |ss|
    ss.dependency 'FBSDKCoreKit/Basics'
    ss.exclude_files = 'FBSDKCoreKit/FBSDKCoreKit/Basics/*',
                       'FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.{h,m}',
                       'FBSDKCoreKit/FBSDKCoreKit/include/**/*',
                       'FBSDKCoreKit/FBSDKCoreKit/Swift/Exports.swift'
    ss.source_files = 'FBSDKCoreKit/FBSDKCoreKit/**/*.{h,hpp,m,mm,swift}'
    ss.public_header_files = 'FBSDKCoreKit/FBSDKCoreKit/Internal/**/*.h',
                             'FBSDKCoreKit/FBSDKCoreKit/AppEvents/Internal/**/*.h',
                             'FBSDKCoreKit/FBSDKCoreKit/*.h',
                             'FBSDKCoreKit/FBSDKCoreKit/AppEvents/*.h',
                             'FBSDKCoreKit/FBSDKCoreKit/AppLink/*.h',
                             'FBSDKCoreKit/FBSDKCoreKit/GraphAPI/*.h'
    ss.private_header_files = 'FBSDKCoreKit/FBSDKCoreKit/Internal/**/*.h',
                              'FBSDKCoreKit/FBSDKCoreKit/AppEvents/Internal/**/*.h'
    ss.resources = 'FacebookSDKStrings.bundle'
    ss.library = 'c++', 'stdc++'
  end
end
