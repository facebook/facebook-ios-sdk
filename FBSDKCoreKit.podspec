# Use the --use-libraries switch when pushing or linting this podspec

Pod::Spec.new do |s|

  s.name         = "FBSDKCoreKit"
  s.version      = "4.7.1"
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

  s.platform     = :ios, "9.0"
  s.ios.deployment_target = "7.0"

  s.source       = { :git => "https://github.com/facebook/facebook-ios-sdk.git",
                     :tag => "sdk-version-4.7.1"
                    }

  s.weak_frameworks = "Accounts", "CoreLocation", "Social", "Security", "QuartzCore", "CoreGraphics", "UIKit", "Foundation", "AudioToolbox"

  s.dependency 'Bolts', '~> 1.1'

  s.header_dir = "FBSDKCoreKit"

  # set header_mappings_dir to resolve our quoted imports in the +Internal file.
  s.header_mappings_dir = "FBSDKCoreKit/FBSDKCoreKit/Internal"

  # The following subspecs are only to disable ARC on certain files. They should not be used as dependencies in your Podfile.
  s.subspec 'arc' do |sp|
    sp.public_header_files = "FBSDKCoreKit/FBSDKCoreKit/*.h"
    sp.source_files   = "FBSDKCoreKit/FBSDKCoreKit/**/*.{h,m}"
    sp.exclude_files = "FBSDKCoreKit/FBSDKCoreKit/Internal/FBSDKDynamicFrameworkLoader.m"
    sp.requires_arc = true
  end

  s.subspec 'no-arc' do |sp|
    sp.source_files = "FBSDKCoreKit/FBSDKCoreKit/Internal/FBSDKDynamicFrameworkLoader.m"
    sp.requires_arc = false
    sp.dependency 'FBSDKCoreKit/arc'
  end
end
