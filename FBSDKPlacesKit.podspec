# Use the --use-libraries switch when pushing or linting this podspec

Pod::Spec.new do |s|

  s.name         = 'FBSDKPlacesKit'
  s.version      = '5.5.0'
  s.summary      = 'Official Facebook SDK for iOS to access Facebook Places'

  s.description  = <<-DESC
                   The Facebook SDK for iOS PlacesKit framework provides:
                   * Search for Places in the Facebook Places graph.
                   * Find the current place a user is in.
                   DESC

  s.homepage     = 'https://developers.facebook.com/docs/ios/'
  s.license      = { :type => 'Facebook Platform License', :file => 'LICENSE' }
  s.author       = 'Facebook'

  s.platform     = :ios
  s.ios.deployment_target = '8.0'

  s.source       = { :git => 'https://github.com/facebook/facebook-objc-sdk.git',
                     :tag => "v#{s.version}"
                    }

  s.weak_frameworks = 'Accounts', 'CoreLocation', 'Social', 'Security', 'Foundation'

  s.requires_arc = true

  s.source_files   = 'FBSDKPlacesKit/FBSDKPlacesKit/**/*.{h,m}'
  s.public_header_files = 'FBSDKPlacesKit/FBSDKPlacesKit/*.{h}'
  s.dependency 'FBSDKCoreKit', "~> 5.0"

end
