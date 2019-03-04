Pod::Spec.new do |s|
  s.name         = 'FBSDKCoreKitSwift'
  s.version      = '0.1.0'
  s.author       = 'Facebook'
  s.homepage     = 'https://developers.facebook.com/docs/swift'
  s.documentation_url = 'https://developers.facebook.com/docs/swift/reference'
  s.license      = { :type => 'Facebook Platform License', :file => 'LICENSE' }

  s.summary      = "Official Facebook SDK in Swift to access Facebook Platform's core features."
  s.description  = <<-DESC
                   The Facebook SDK in Swift Core framework provides:
                   * App Events (for App Analytics)
                   * Graph API Access and Error Recovery
                   * Working with Access Tokens and User Profiles
                   DESC

  s.source       = { :git => 'https://github.com/facebook/facebook-objc-sdk.git', :tag => s.version.to_s }

  s.requires_arc = true
  s.platform     = :ios

  s.swift_version = '4.2'

  s.ios.deployment_target = '8.0'

  s.source_files = 'FBSDKCoreKitSwift/FBSDKCoreKitSwift/**/*.{swift,h,m}'
  s.module_name = 'FBSDKCoreKitSwift'
  s.pod_target_xcconfig = { 'ENABLE_TESTABILITY' => 'YES' }

  s.ios.dependency 'FBSDKCoreKit'
end
