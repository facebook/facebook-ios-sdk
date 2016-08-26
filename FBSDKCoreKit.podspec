# Use the --use-libraries switch when pushing or linting this podspec

Pod::Spec.new do |s|

  s.name         = "FBSDKCoreKit"
  s.version      = "4.15.0"
  s.summary      = "Official Facebook SDK for iOS to access Facebook Platform's core features"

  s.description  = <<-DESC
                   The Facebook SDK for iOS CoreKit framework provides:
                   * App Events (for App Analytics)
                   * Graph API Access and Error Recovery
                   * Working with Access Tokens and User Profiles
                   DESC

  s.homepage     = "https://developers.facebook.com/docs/ios/"
  s.license      = { :type => "Facebook Platform License", :file => "LICENSE" }
  s.author       = 'Facebook'

  s.platform     = :ios, :tvos
  s.ios.deployment_target = '7.0'
  s.tvos.deployment_target = '9.0'

  s.source       = { :git => "https://github.com/facebook/facebook-ios-sdk.git",
                     :tag => "sdk-version-4.15.0"
                    }

  s.ios.weak_frameworks = 'Accounts', 'CoreLocation', 'Social', 'Security', 'QuartzCore', 'CoreGraphics', 'UIKit', 'Foundation', 'AudioToolbox'
  s.tvos.weak_frameworks = 'CoreLocation', 'Security', 'QuartzCore', 'CoreGraphics', 'UIKit', 'Foundation', 'AudioToolbox'

  s.public_header_files = 'FBSDKCoreKit/FBSDKCoreKit/*.h'
  s.source_files = 'FBSDKCoreKit/FBSDKCoreKit/**/*.{h,m}'
  s.resources = 'FacebookSDKStrings.bundle'
  s.ios.exclude_files = 'FBSDKCoreKit/FBSDKCoreKit/FBSDKDeviceButton.{h,m}',
                        'FBSDKCoreKit/FBSDKCoreKit/FBSDKDeviceViewControllerBase.{h,m}',
                        'FBSDKCoreKit/FBSDKCoreKit/Internal/Device/**/*'
  s.tvos.exclude_files = 'FBSDKCoreKit/FBSDKCoreKit/FBSDKAppLinkResolver.{h,m}',
                          'FBSDKCoreKit/FBSDKCoreKit/FBSDKAppLinkUtility.{h,m}',
                          'FBSDKCoreKit/FBSDKCoreKit/FBSDKGraphErrorRecoveryProcessor.{h,m}',
                          'FBSDKCoreKit/FBSDKCoreKit/FBSDKMutableCopying.h',
                          'FBSDKCoreKit/FBSDKCoreKit/FBSDKProfile.{h,m}',
                          'FBSDKCoreKit/FBSDKCoreKit/FBSDKProfilePictureView.{h,m}',
                          'FBSDKCoreKit/FBSDKCoreKit/Internal/AppLink/**/*',
                          'FBSDKCoreKit/FBSDKCoreKit/Internal/BridgeAPI/**/*',
                          'FBSDKCoreKit/FBSDKCoreKit/Internal/Cryptography/**/*',
                          'FBSDKCoreKit/FBSDKCoreKit/Internal/FBSDKAudioResourceLoader.{h,m}',
                          'FBSDKCoreKit/FBSDKCoreKit/Internal/FBSDKContainerViewController.{h,m}',
                          'FBSDKCoreKit/FBSDKCoreKit/Internal/FBSDKMonotonicTime.{h,m}',
                          'FBSDKCoreKit/FBSDKCoreKit/Internal/FBSDKProfile+Internal.h',
                          'FBSDKCoreKit/FBSDKCoreKit/Internal/FBSDKSystemAccountStoreAdapter.{h,m}',
                          'FBSDKCoreKit/FBSDKCoreKit/Internal/FBSDKTriStateBOOL.{h,m}',
                          'FBSDKCoreKit/FBSDKCoreKit/Internal/UI/FBSDKCloseIcon.{h,m}',
                          'FBSDKCoreKit/FBSDKCoreKit/Internal/UI/FBSDKColor.{h,m}',
                          'FBSDKCoreKit/FBSDKCoreKit/Internal/UI/FBSDKMaleSilhouetteIcon.{h,m}',
                          'FBSDKCoreKit/FBSDKCoreKit/Internal/WebDialog/**/*'

  # This excludes `FBSDKCoreKit/FBSDKCoreKit/Internal_NoARC/` folder, as that folder includes only `no-arc` files.
  s.requires_arc = ['FBSDKCoreKit/FBSDKCoreKit/*',
                    'FBSDKCoreKit/FBSDKCoreKit/Internal/**/*']

  s.ios.dependency 'Bolts', '~> 1.7'
end
