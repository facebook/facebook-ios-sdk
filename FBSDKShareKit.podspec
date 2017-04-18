# Use the --use-libraries switch when pushing or linting this podspec

Pod::Spec.new do |s|

  s.name         = "FBSDKShareKit"
  s.version      = "4.22.0"
  s.summary      = "Official Facebook SDK for iOS to access Facebook Platform's Sharing Features"

  s.description  = <<-DESC
                   The Facebook SDK for iOS ShareKit framework provides:
                   * Share content with Share Dialog and Message Dialog.
                   * Send Game Requests or App Invites to grow your app.
                   * Publish content and open graph stories with the Graph API
                   DESC

  s.homepage     = "https://developers.facebook.com/docs/ios/"
  s.license      = { :type => "Facebook Platform License", :file => "LICENSE" }
  s.author       = 'Facebook'

  s.platform     = :ios, :tvos
  s.ios.deployment_target = '7.0'
  s.tvos.deployment_target = '9.0'

  s.source       = { :git => "https://github.com/facebook/facebook-ios-sdk.git",
                     :tag => "sdk-version-4.22.0"
                    }

  s.ios.weak_frameworks = 'Accounts', 'AudioToolbox', 'CoreGraphics', 'CoreLocation', 'Foundation', 'QuartzCore', 'Security', 'Social', 'UIKit'
  s.tvos.weak_frameworks = 'AudioToolbox', 'CoreGraphics', 'CoreLocation', 'Foundation', 'QuartzCore', 'Security', 'UIKit'

  s.requires_arc = true

  s.ios.source_files = 'FBSDKShareKit/FBSDKShareKit/**/*.{h,m}'
  s.ios.public_header_files = 'FBSDKShareKit/FBSDKShareKit/*.{h}'
  s.ios.exclude_files = 'FBSDKShareKit/FBSDKShareKit/FBSDKDeviceShareButton.{h,m}',
                        'FBSDKShareKit/FBSDKShareKit/FBSDKDeviceShareViewController.{h,m}'
  s.tvos.source_files = 'FBSDKShareKit/FBSDKShareKit/FBSDKDeviceShareButton.{h,m}',
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
                        'FBSDKShareKit/FBSDKShareKit/Internal/FBSDKShareDefines.h',
                        'FBSDKShareKit/FBSDKShareKit/Internal/FBSDKShareError.{h,m}',
                        'FBSDKShareKit/FBSDKShareKit/Internal/FBSDKShareLinkContent+Internal.h',
                        'FBSDKShareKit/FBSDKShareKit/Internal/FBSDKShareOpenGraphValueContainer+Internal.h',
                        'FBSDKShareKit/FBSDKShareKit/Internal/FBSDKShareUtility.{h,m}',
                        'FBSDKShareKit/FBSDKShareKit/Internal/FBSDKVideoUploader.{h,m}'
  s.tvos.public_header_files = 'FBSDKShareKit/FBSDKShareKit/FBSDKDeviceShareButton.h',
                               'FBSDKShareKit/FBSDKShareKit/FBSDKDeviceShareViewController.h',
                               'FBSDKShareKit/FBSDKShareKit/FBSDKShareAPI.h',
                               'FBSDKShareKit/FBSDKShareKit/FBSDKShareConstants.h',
                               'FBSDKShareKit/FBSDKShareKit/FBSDKHashtag.h',
                               'FBSDKShareKit/FBSDKShareKit/FBSDKShareKit.h',
                               'FBSDKShareKit/FBSDKShareKit/FBSDKShareLinkContent.h',
                               'FBSDKShareKit/FBSDKShareKit/FBSDKShareOpenGraphAction.h',
                               'FBSDKShareKit/FBSDKShareKit/FBSDKShareOpenGraphContent.h',
                               'FBSDKShareKit/FBSDKShareKit/FBSDKShareOpenGraphObject.h',
                               'FBSDKShareKit/FBSDKShareKit/FBSDKShareOpenGraphValueContainer.h',
                               'FBSDKShareKit/FBSDKShareKit/FBSDKSharePhoto.h',
                               'FBSDKShareKit/FBSDKShareKit/FBSDKSharePhotoContent.h',
                               'FBSDKShareKit/FBSDKShareKit/FBSDKShareVideo.h',
                               'FBSDKShareKit/FBSDKShareKit/FBSDKShareVideoContent.h',
                               'FBSDKShareKit/FBSDKShareKit/FBSDKSharing.h',
                               'FBSDKShareKit/FBSDKShareKit/FBSDKSharingContent.h'

  s.header_dir = "FBSDKShareKit"
  # Allow the weak linking to Bolts (see FBSDKAppLinkResolver.h) in Cocoapods 0.39.0
  s.pod_target_xcconfig = { 'CLANG_ALLOW_NON_MODULAR_INCLUDES_IN_FRAMEWORK_MODULES' => 'YES' }
  s.dependency 'FBSDKCoreKit'

end
