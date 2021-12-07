

Pod::Spec.new do |s|

  s.name         = 'FBSDKCoreKit'
  s.version      = '8.8.0'
  s.summary      = 'Official Facebook SDK for iOS to access Facebook Platform core features'

  s.description  = <<-DESC
                   The Facebook SDK for iOS CoreKit framework provides:
                   * App Events (for App Analytics)
                   * Graph API Access and Error Recovery
                   * Working with Access Tokens and User Profiles
                   DESC

  s.homepage     = 'https://developers.facebook.com/docs/ios/'
  }
  s.author       = 'Facebook'

  s.platform     = :ios, :tvos
  s.ios.deployment_target = '10.0'
  s.tvos.deployment_target = '10.0'

  s.source = {
      http: "https://github.com/facebook/facebook-ios-sdk/releases/download/v#{8.8.0
}/FacebookSDK_Dynamic.xcframework.zip",
      sha1: '0d224ddaaaf248a79f0a9d5abaf125ad6c29aa15'
  }
  s.vendored_frameworks = 'XCFrameworks/FBSDKCoreKit.xcframework'
  s.dependency 'FBSDKCoreKit_Basics', "#{8.8.0}"
  s.ios.dependency 'FBAEMKit', "#{8.8.0}"
end
