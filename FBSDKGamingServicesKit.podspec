# Use the --use-libraries switch when pushing or linting this podspec

Pod::Spec.new do |s|

  s.name         = 'FBSDKGamingServicesKit'
  s.version      = '8.0.0'
  s.summary      = 'Official Facebook SDK for iOS to access Facebook Gaming Services'

  s.description  = <<-DESC
                   The Facebook SDK for iOS GamingKit framework provides:
                   * Friend Finder.
                   DESC

  s.homepage     = 'https://developers.facebook.com/docs/ios/'
  s.license      = { type: 'Facebook Platform License', file: 'LICENSE' }
  s.author       = 'Facebook'

  s.platform     = :ios
  s.ios.deployment_target = '9.0'

  s.swift_version = '5.0'

  s.source       = {
    git: 'https://github.com/facebook/facebook-ios-sdk.git',
    tag: "v#{s.version}"
  }

  s.weak_frameworks = 'Accounts', 'Social', 'Security', 'Foundation'

  s.requires_arc = true
  s.pod_target_xcconfig = { 'DEFINES_MODULE': 'YES' }
  s.prefix_header_contents = '#define FBSDKCOCOAPODS'

  s.source_files   = 'FBSDKGamingServicesKit/FBSDKGamingServicesKit/**/*.{h,m}'
  s.public_header_files = 'FBSDKGamingServicesKit/FBSDKGamingServicesKit/*.{h}'
  s.dependency 'FBSDKShareKit', "~> #{s.version}"

end
