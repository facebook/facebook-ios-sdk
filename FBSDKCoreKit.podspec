# Use the --use-libraries switch when pushing or linting this podspec

Pod::Spec.new do |s|

  s.name         = 'FBSDKCoreKit'
  s.version      = '5.5.0'
  s.summary      = 'Official Facebook SDK for iOS to access Facebook Platform core features'

  s.description  = <<-DESC
                   The Facebook SDK for iOS CoreKit framework provides:
                   * App Events (for App Analytics)
                   * Graph API Access and Error Recovery
                   * Working with Access Tokens and User Profiles
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
  s.tvos.weak_frameworks = 'CoreLocation', 'Security', 'QuartzCore', 'CoreGraphics', 'UIKit', 'Foundation', 'AudioToolbox'

  # This excludes `FBSDKCoreKit/FBSDKCoreKit/Internal_NoARC/` folder, as that folder includes only `no-arc` files.
  s.requires_arc = ['FBSDKCoreKit/FBSDKCoreKit/*',
                    'FBSDKCoreKit/FBSDKCoreKit/AppEvents/**/*',
                    'FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*',
		                'FBSDKCoreKit/FBSDKCoreKit/Basics/**/*',
                    'FBSDKCoreKit/FBSDKCoreKit/Internal/**/*']

  s.subspec 'Basics' do |ss|
    ss.source_files = 'FBSDKCoreKit/FBSDKCoreKit/Basics/*.{h,m}',
                      'FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.{h,m}'
    ss.public_header_files = 'FBSDKCoreKit/FBSDKCoreKit/Basics/*.h'
    ss.library = 'z'
  end

  s.subspec 'Core' do |ss|
    ss.dependency 'FBSDKCoreKit/Basics'
    ss.exclude_files = 'FBSDKCoreKit/FBSDKCoreKit/Basics/*',
                       'FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.{h,m}'
    ss.source_files = 'FBSDKCoreKit/FBSDKCoreKit/**/*.{h,m}'
    ss.public_header_files = 'FBSDKCoreKit/FBSDKCoreKit/*.h',
                             'FBSDKCoreKit/FBSDKCoreKit/AppEvents/*.h',
                             'FBSDKCoreKit/FBSDKCoreKit/AppLink/*.h'
    ss.resources = 'FacebookSDKStrings.bundle'
    ss.ios.exclude_files = 'FBSDKCoreKit/FBSDKCoreKit/FBSDKDeviceButton.{h,m}',
                           'FBSDKCoreKit/FBSDKCoreKit/FBSDKDeviceViewControllerBase.{h,m}',
                           'FBSDKCoreKit/FBSDKCoreKit/Internal/Device/**/*'
    ss.tvos.exclude_files = 'FBSDKCoreKit/FBSDKCoreKit/AppEvents/Internal/Codeless/*',
                            'FBSDKCoreKit/FBSDKCoreKit/AppEvents/Internal/FBSDKHybridAppEventsScriptMessageHandler.{h,m}',
                            'FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*',
                            'FBSDKCoreKit/FBSDKCoreKit/FBSDKGraphErrorRecoveryProcessor.{h,m}',
                            'FBSDKCoreKit/FBSDKCoreKit/FBSDKMeasurementEvent.{h,m}',
                            'FBSDKCoreKit/FBSDKCoreKit/FBSDKMutableCopying.h',
                            'FBSDKCoreKit/FBSDKCoreKit/FBSDKProfile.{h,m}',
                            'FBSDKCoreKit/FBSDKCoreKit/FBSDKProfilePictureView.{h,m}',
                            'FBSDKCoreKit/FBSDKCoreKit/FBSDKURL.{h,m}',
                            'FBSDKCoreKit/FBSDKCoreKit/Internal/BridgeAPI/**/*',
                            'FBSDKCoreKit/FBSDKCoreKit/Internal/FBSDKAppLinkReturnToRefererView_Internal.h',
                            'FBSDKCoreKit/FBSDKCoreKit/Internal/FBSDKAppLink_Internal.h',
                            'FBSDKCoreKit/FBSDKCoreKit/Internal/FBSDKAudioResourceLoader.{h,m}',
                            'FBSDKCoreKit/FBSDKCoreKit/Internal/FBSDKContainerViewController.{h,m}',
                            'FBSDKCoreKit/FBSDKCoreKit/Internal/FBSDKMeasurementEvent_Internal.h',
                            'FBSDKCoreKit/FBSDKCoreKit/Internal/FBSDKMonotonicTime.{h,m}',
                            'FBSDKCoreKit/FBSDKCoreKit/Internal/FBSDKProfile+Internal.h',
                            'FBSDKCoreKit/FBSDKCoreKit/Internal/FBSDKSystemAccountStoreAdapter.{h,m}',
                            'FBSDKCoreKit/FBSDKCoreKit/Internal/FBSDKTriStateBOOL.{h,m}',
                            'FBSDKCoreKit/FBSDKCoreKit/Internal/FBSDKURL_Internal.h',
                            'FBSDKCoreKit/FBSDKCoreKit/Internal/UI/FBSDKCloseIcon.{h,m}',
                            'FBSDKCoreKit/FBSDKCoreKit/Internal/UI/FBSDKColor.{h,m}',
                            'FBSDKCoreKit/FBSDKCoreKit/Internal/UI/FBSDKMaleSilhouetteIcon.{h,m}',
                            'FBSDKCoreKit/FBSDKCoreKit/Internal/WebDialog/**/*'
  end
end
