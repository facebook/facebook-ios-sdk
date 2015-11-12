# Use the --use-libraries switch when pushing or linting this podspec

Pod::Spec.new do |s|

  s.name         = "FBSDKShareKit"
  s.version      = "4.8.0"
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

  s.platform     = :ios, "9.0"
  s.ios.deployment_target = "7.0"

  s.source       = { :git => "https://github.com/facebook/facebook-ios-sdk.git",
                     :tag => "sdk-version-4.8.0"
                    }

  s.weak_frameworks = "Accounts", "CoreLocation", "Social", "Security", "QuartzCore", "CoreGraphics", "UIKit", "Foundation", "AudioToolbox"

  s.requires_arc = true

  s.source_files   = "FBSDKShareKit/FBSDKShareKit/**/*.{h,m}"
  s.public_header_files = "FBSDKShareKit/FBSDKShareKit/*.{h}"
  s.header_dir = "FBSDKShareKit"
  s.dependency 'FBSDKCoreKit'

end
