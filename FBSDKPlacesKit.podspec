# Use the --use-libraries switch when pushing or linting this podspec

Pod::Spec.new do |s|

  s.name         = "FBSDKPlacesKit"
  s.version      = "4.22.0"
  s.summary      = "Official Facebook SDK for iOS to access Facebook Places"

  s.description  = <<-DESC
                   The Facebook SDK for iOS PlacesKit framework provides:
                   * Search for Places in the Facebook Places graph.
                   * Find the current place a user is in.
                   DESC

  s.homepage     = "https://developers.facebook.com/docs/ios/"
  s.license      = { :type => "Facebook Platform License", :file => "LICENSE" }
  s.author       = 'Facebook'

  s.platform     = :ios, "9.0"
  s.ios.deployment_target = "7.0"

  s.source       = { :git => "https://github.com/facebook/facebook-ios-sdk.git",
                     :tag => "sdk-version-4.22.0"
                    }

  s.weak_frameworks = "Accounts", "CoreLocation", "Social", "Security", "Foundation"

  s.requires_arc = true

  s.source_files   = "FBSDKPlacesKit/FBSDKPlacesKit/**/*.{h,m}"
  s.public_header_files = "FBSDKPlacesKit/FBSDKPlacesKit/*.{h}"
  # Allow the weak linking to Bolts (see FBSDKAppLinkResolver.h) in Cocoapods 0.39.0
  s.pod_target_xcconfig = { 'CLANG_ALLOW_NON_MODULAR_INCLUDES_IN_FRAMEWORK_MODULES' => 'YES' }
  s.dependency 'FBSDKCoreKit'

end
