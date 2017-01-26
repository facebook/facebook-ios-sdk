# Use the --use-libraries switch when pushing or linting this podspec

Pod::Spec.new do |s|

  s.name         = 'FBSDKTVOSKit'
  s.version      = '4.19.0'
  s.summary      = 'Official Facebook SDK for tvOS to access Facebook Platform with features like Login and Graph API.'

  s.description  = <<-DESC
                   The Facebook SDK for tvOS Kit framework provides Facebook Login with a confirmation code
                   to easily sign in users on Apple TV without using the remote.
                   See FBSDKCoreKit for additional functionality like Analytics for Apps and Graph API.
                   DESC

  s.homepage     = 'https://developers.facebook.com/docs/tvos'
  s.license      = { :type => 'Facebook Platform License', :file => 'LICENSE' }
  s.author       = 'Facebook'

  s.platform     = :tvos
  s.tvos.deployment_target = '9.0'

  s.source       = { :git => 'https://github.com/facebook/facebook-ios-sdk.git',
                     :tag => 'sdk-version-4.19.0' }

  s.source_files   = 'FBSDKTVOSKit/FBSDKTVOSKit/**/*.{h,m}'
  s.public_header_files = 'FBSDKTVOSKit/FBSDKTVOSKit/*.h'
  s.header_dir = 'FBSDKTVOSKit'

  s.dependency 'FBSDKCoreKit', '~> 4.11'
  # We have a compile time depend on FBSDKShareKit
  s.dependency 'FBSDKShareKit', '~> 4.11'
end
