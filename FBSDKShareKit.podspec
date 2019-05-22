# Use the --use-libraries switch when pushing or linting this podspec

Pod::Spec.new do |s|

  s.name         = 'FBSDKShareKit'
  s.version      = '5.0.1'
  s.summary      = 'Official Facebook SDK for iOS to access Facebook Platform Sharing Features'

  s.description  = <<-DESC
                   The Facebook SDK for iOS ShareKit framework provides:
                   * Share content with Share Dialog and Message Dialog.
                   * Send Game Requests or App Invites to grow your app.
                   * Publish content and open graph stories with the Graph API
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

  s.ios.weak_frameworks = 'Accounts', 'AudioToolbox', 'CoreGraphics', 'CoreLocation', 'Foundation', 'QuartzCore', 'Security', 'Social', 'UIKit'
  s.tvos.weak_frameworks = 'AudioToolbox', 'CoreGraphics', 'CoreLocation', 'Foundation', 'QuartzCore', 'Security', 'UIKit'

  s.requires_arc = true

  s.header_dir = 'FBSDKShareKit'
  s.dependency 'FBSDKCoreKit', "~> 5.0"

  s.public_header_files = 'FBSDKShareKit/FBSDKShareKit/*.{h}'
  s.ios.source_files = 'FBSDKShareKit/FBSDKShareKit/**/*.{h,m}'
  s.ios.exclude_files = 'FBSDKShareKit/FBSDKShareKit/FBSDKDeviceShareButton.{h,m}',
                        'FBSDKShareKit/FBSDKShareKit/FBSDKDeviceShareViewController.{h,m}'
  s.tvos.exclude_files = 'FBSDKShareKit/FBSDKShareKit/FBSDKAppGroupAddDialog.{h,m}',
                         'FBSDKShareKit/FBSDKShareKit/FBSDKAppGroupContent.{h,m}',
                         'FBSDKShareKit/FBSDKShareKit/FBSDKAppGroupJoinDialog.{h,m}',
                         'FBSDKShareKit/FBSDKShareKit/FBSDKAppInviteContent.{h,m}',
                         'FBSDKShareKit/FBSDKShareKit/FBSDKAppInviteDialog.{h,m}',
                         'FBSDKShareKit/FBSDKShareKit/FBSDKCameraEffectArguments.{h,m}',
                         'FBSDKShareKit/FBSDKShareKit/FBSDKCameraEffectTextures.{h,m}',
                         'FBSDKShareKit/FBSDKShareKit/FBSDKGameRequestContent.{h,m}',
                         'FBSDKShareKit/FBSDKShareKit/FBSDKGameRequestDialog.{h,m}',
                         'FBSDKShareKit/FBSDKShareKit/FBSDKLikeButton.{h,m}',
                         'FBSDKShareKit/FBSDKShareKit/FBSDKLikeControl.{h,m}',
                         'FBSDKShareKit/FBSDKShareKit/FBSDKLikeObjectType.{h,m}',
                         'FBSDKShareKit/FBSDKShareKit/FBSDKLiking.{h,m}',
                         'FBSDKShareKit/FBSDKShareKit/FBSDKMessageDialog.{h,m}',
                         'FBSDKShareKit/FBSDKShareKit/FBSDKSendButton.{h,m}',
                         'FBSDKShareKit/FBSDKShareKit/FBSDKShareButton.{h,m}',
                         'FBSDKShareKit/FBSDKShareKit/FBSDKShareCameraEffectContent.{h,m}',
                         'FBSDKShareKit/FBSDKShareKit/FBSDKShareDialog.{h,m}',
                         'FBSDKShareKit/FBSDKShareKit/FBSDKShareDialogMode.{h,m}',
                         'FBSDKShareKit/FBSDKShareKit/FBSDKSharingButton.{h,m}',
                         'FBSDKShareKit/FBSDKShareKit/FBSDKSharingScheme.{h,m}'
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
                        'FBSDKShareKit/FBSDKShareKit/FBSDKSharingValidation.h',
                        'FBSDKShareKit/FBSDKShareKit/FBSDKShareMessengerActionButton.h',
                        'FBSDKShareKit/FBSDKShareKit/FBSDKShareMessengerGenericTemplateContent.h',
                        'FBSDKShareKit/FBSDKShareKit/FBSDKShareMessengerGenericTemplateElement.h',
                        'FBSDKShareKit/FBSDKShareKit/FBSDKShareMessengerMediaTemplateContent.h',
                        'FBSDKShareKit/FBSDKShareKit/FBSDKShareMessengerOpenGraphMusicTemplateContent.h',
                        'FBSDKShareKit/FBSDKShareKit/FBSDKShareMessengerURLActionButton.h',
                        'FBSDKShareKit/FBSDKShareKit/Internal/FBSDKShareDefines.h',
                        'FBSDKShareKit/FBSDKShareKit/Internal/FBSDKShareError.{h,m}',
                        'FBSDKShareKit/FBSDKShareKit/Internal/FBSDKShareOpenGraphValueContainer+Internal.h',
                        'FBSDKShareKit/FBSDKShareKit/Internal/FBSDKShareUtility.{h,m}',
                        'FBSDKShareKit/FBSDKShareKit/Internal/FBSDKVideoUploader.{h,m}'
end
