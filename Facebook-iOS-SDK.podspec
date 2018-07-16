# If you've made changes to the SDK (such as file paths), consider using `pod lib lint` to lint locally and then using the :path option in your Podfile

Pod::Spec.new do |s|

  s.name         = "Facebook-iOS-SDK"
  s.version      = "SDK_VERSION_TO_RELEASE"
  s.summary      = "Official Facebook SDK for iOS to access Facebook Platform with features like Login, Share and Message Dialog, App Links, and Graph API"

  s.description  = <<-DESC
                   The Facebook SDK for iOS enables you to use Facebook's Platform such as:
                   * Facebook Login to easily sign in users.
                   * Sharing features like the Share or Message Dialog to grow your app.
                   * Simpler Graph API access to provide more social context.
                   DESC

  s.homepage     = "https://developers.facebook.com/docs/ios/"
  s.license      = { :type => "Facebook Platform License", :file => "LICENSE" }
  s.author       = 'Facebook'

  s.platform     = :ios, :tvos
  s.ios.deployment_target = '7.0'
  s.tvos.deployment_target = '9.0'

  s.source       = { :git => "https://github.com/facebook/facebook-ios-sdk.git",
                     :tag => "sdk-version-SDK_VERSION_TO_RELEASE"
                    }

  s.ios.weak_frameworks = 'Accounts', 'CoreLocation', 'Social', 'Security', 'QuartzCore', 'CoreGraphics', 'UIKit', 'Foundation', 'AudioToolbox', 'WebKit'
  s.tvos.weak_frameworks = 'CoreLocation', 'Security', 'QuartzCore', 'CoreGraphics', 'UIKit', 'Foundation', 'AudioToolbox'

  s.requires_arc = true

  s.dependency 'Bolts', '~> 1.7'

  s.subspec 'CoreKit' do |spec|
    spec.requires_arc = false
    spec.public_header_files = 'FBSDKCoreKit/FBSDKCoreKit/*.h'
    spec.source_files = 'FBSDKCoreKit/FBSDKCoreKit/**/*.{h,m}'
    spec.resources = 'FacebookSDKStrings.bundle'
    spec.header_dir = 'FBSDKCoreKit'
    spec.ios.exclude_files = 'FBSDKCoreKit/FBSDKCoreKit/FBSDKDeviceButton.{h,m}',
                          'FBSDKCoreKit/FBSDKCoreKit/FBSDKDeviceViewControllerBase.{h,m}',
                          'FBSDKCoreKit/FBSDKCoreKit/Internal/Device/**/*'
    spec.tvos.exclude_files = 'FBSDKCoreKit/FBSDKCoreKit/FBSDKAppLinkResolver.{h,m}',
                            'FBSDKCoreKit/FBSDKCoreKit/FBSDKAppLinkUtility.{h,m}',
                            'FBSDKCoreKit/FBSDKCoreKit/FBSDKGraphErrorRecoveryProcessor.{h,m}',
                            'FBSDKCoreKit/FBSDKCoreKit/FBSDKMutableCopying.h',
                            'FBSDKCoreKit/FBSDKCoreKit/FBSDKProfile.{h,m}',
                            'FBSDKCoreKit/FBSDKCoreKit/FBSDKProfilePictureView.{h,m}',
                            'FBSDKCoreKit/FBSDKCoreKit/Internal/AppLink/**/*',
                            'FBSDKCoreKit/FBSDKCoreKit/Internal/AppEvents/Codeless/*',
                            'FBSDKCoreKit/FBSDKCoreKit/Internal/AppEvents/FBSDKHybridAppEventsScriptMessageHandler.{h,m}',
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
    spec.requires_arc = ['FBSDKCoreKit/FBSDKCoreKit/*',
                      'FBSDKCoreKit/FBSDKCoreKit/Internal/**/*']
  end
  s.subspec 'LoginKit' do |spec|
    spec.ios.source_files   = 'FBSDKLoginKit/FBSDKLoginKit/**/*.{h,m}'
    spec.ios.public_header_files = 'FBSDKLoginKit/FBSDKLoginKit/*.{h}'
    spec.header_dir = 'FBSDKLoginKit'
    spec.tvos.source_files = 'FBSDKLoginKit/FBSDKLoginKit/FBSDKLoginConstants.{h,m}',
                          'FBSDKLoginKit/FBSDKLoginKit/FBSDKDeviceLoginCodeInfo.{h,m}',
                          'FBSDKLoginKit/FBSDKLoginKit/FBSDKDeviceLoginManager.{h,m}',
                          'FBSDKLoginKit/FBSDKLoginKit/FBSDKDeviceLoginManagerResult.{h,m}',
                          'FBSDKLoginKit/FBSDKLoginKit/Internal/FBSDKDeviceLoginCodeInfo+Internal.h',
                          'FBSDKLoginKit/FBSDKLoginKit/Internal/FBSDKDeviceLoginError.{h,m}',
                          'FBSDKLoginKit/FBSDKLoginKit/Internal/FBSDKDeviceLoginManagerResult+Internal.h'
    spec.tvos.public_header_files = 'FBSDKLoginKit/FBSDKLoginKit/FBSDKDeviceLoginCodeInfo.h',
                                 'FBSDKLoginKit/FBSDKLoginKit/FBSDKDeviceLoginManager.h',
                                 'FBSDKLoginKit/FBSDKLoginKit/FBSDKDeviceLoginManagerResult.h',
                                 'FBSDKLoginKit/FBSDKLoginKit/FBSDKLoginConstants.h'

    # Allow the weak linking to Bolts (see FBSDKAppLinkResolver.h) in Cocoapods 0.39.0
    spec.pod_target_xcconfig = { 'CLANG_ALLOW_NON_MODULAR_INCLUDES_IN_FRAMEWORK_MODULES' => 'YES' }
    spec.dependency 'Facebook-iOS-SDK/CoreKit'
  end
  s.subspec 'ShareKit' do |spec|
    spec.requires_arc = true
    spec.ios.source_files = 'FBSDKShareKit/FBSDKShareKit/**/*.{h,m}'
    spec.public_header_files = 'FBSDKShareKit/FBSDKShareKit/*.{h}'
    spec.ios.exclude_files = 'FBSDKShareKit/FBSDKShareKit/FBSDKDeviceShareButton.{h,m}',
                          'FBSDKShareKit/FBSDKShareKit/FBSDKDeviceShareViewController.{h,m}'
    spec.tvos.source_files = 'FBSDKShareKit/FBSDKShareKit/FBSDKDeviceShareButton.{h,m}',
                          'FBSDKShareKit/FBSDKShareKit/FBSDKDeviceShareViewController.{h,m}',
                          'FBSDKShareKit/FBSDKShareKit/FBSDKHashtag.{h,m}',
                          'FBSDKShareKit/FBSDKShareKit/FBSDKShareKit.h',
                          'FBSDKShareKit/FBSDKShareKit/FBSDKShareAPI.{h,m}',
                          'FBSDKShareKit/FBSDKShareKit/FBSDKShareConstants.{h,m}',
                          'FBSDKShareKit/FBSDKShareKit/FBSDKShareConstants.{h,m}',
                          'FBSDKShareKit/FBSDKShareKit/FBSDKShareLinkContent.{h,m}',
                          'FBSDKShareKit/FBSDKShareKit/FBSDKShareMediaContent.{h,m}',
                          'FBSDKShareKit/FBSDKShareKit/FBSDKShareOpenGraphAction.{h,m}',
                          'FBSDKShareKit/FBSDKShareKit/FBSDKShareOpenGraphContent.{h,m}',
                          'FBSDKShareKit/FBSDKShareKit/FBSDKShareOpenGraphObject.{h,m}',
                          'FBSDKShareKit/FBSDKShareKit/FBSDKShareOpenGraphValueContainer.{h,m}',
                          'FBSDKShareKit/FBSDKShareKit/FBSDKSharePhoto.{h,m}',
                          'FBSDKShareKit/FBSDKShareKit/FBSDKSharePhotoContent.{h,m}',
                          'FBSDKShareKit/FBSDKShareKit/FBSDKShareVideo.{h,m}',
                          'FBSDKShareKit/FBSDKShareKit/FBSDKShareVideoContent.{h,m}',
                          'FBSDKShareKit/FBSDKShareKit/FBSDKSharing.h',
                          'FBSDKShareKit/FBSDKShareKit/FBSDKSharingContent.h',
                          'FBSDKShareKit/FBSDKShareKit/FBSDKShareMessengerActionButton.h',
                          'FBSDKShareKit/FBSDKShareKit/FBSDKShareMessengerGenericTemplateContent.h',
                          'FBSDKShareKit/FBSDKShareKit/FBSDKShareMessengerGenericTemplateElement.h',
                          'FBSDKShareKit/FBSDKShareKit/FBSDKShareMessengerMediaTemplateContent.h',
                          'FBSDKShareKit/FBSDKShareKit/FBSDKShareMessengerOpenGraphMusicTemplateContent.h',
                          'FBSDKShareKit/FBSDKShareKit/FBSDKShareMessengerURLActionButton.h',
                          'FBSDKShareKit/FBSDKShareKit/Internal/FBSDKShareDefines.h',
                          'FBSDKShareKit/FBSDKShareKit/Internal/FBSDKShareError.{h,m}',
                          'FBSDKShareKit/FBSDKShareKit/Internal/FBSDKShareLinkContent+Internal.h',
                          'FBSDKShareKit/FBSDKShareKit/Internal/FBSDKShareOpenGraphValueContainer+Internal.h',
                          'FBSDKShareKit/FBSDKShareKit/Internal/FBSDKShareUtility.{h,m}',
                          'FBSDKShareKit/FBSDKShareKit/Internal/FBSDKVideoUploader.{h,m}'

    spec.header_dir = "FBSDKShareKit"
    # Allow the weak linking to Bolts (see FBSDKAppLinkResolver.h) in Cocoapods 0.39.0
    spec.pod_target_xcconfig = { 'CLANG_ALLOW_NON_MODULAR_INCLUDES_IN_FRAMEWORK_MODULES' => 'YES' }
    spec.dependency 'Facebook-iOS-SDK/CoreKit'
  end
  s.subspec 'PlacesKit' do |spec|
    spec.platform     = :ios
    spec.requires_arc = true
    spec.source_files   = "FBSDKPlacesKit/FBSDKPlacesKit/**/*.{h,m}"
    spec.public_header_files = "FBSDKPlacesKit/FBSDKPlacesKit/*.{h}"
    # Allow the weak linking to Bolts (see FBSDKAppLinkResolver.h) in Cocoapods 0.39.0
    spec.pod_target_xcconfig = { 'CLANG_ALLOW_NON_MODULAR_INCLUDES_IN_FRAMEWORK_MODULES' => 'YES' }
    spec.dependency 'Facebook-iOS-SDK/CoreKit'
  end
  s.subspec 'TVOSKit' do |spec|
    spec.platform     = :tvos
    spec.source_files   = 'FBSDKTVOSKit/FBSDKTVOSKit/**/*.{h,m}'
    spec.public_header_files = 'FBSDKTVOSKit/FBSDKTVOSKit/*.h'
    spec.header_dir = 'FBSDKTVOSKit'
    spec.dependency 'Facebook-iOS-SDK/CoreKit'
    # We have a compile time depend on FBSDKShareKit
    spec.dependency 'Facebook-iOS-SDK/ShareKit'
    spec.dependency 'Facebook-iOS-SDK/LoginKit'
  end
  s.subspec 'MarketingKit' do |spec|
    spec.platform = :ios
    spec.dependency 'Facebook-iOS-SDK/CoreKit'
    spec.dependency 'FBSDKMarketingKit'
  end
end
