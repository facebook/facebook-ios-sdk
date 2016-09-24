Pod::Spec.new do |s|
  s.name         = 'FacebookCore'
  s.version      = '0.2.0'
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

  s.source       = { :git => 'https://github.com/facebook/facebook-sdk-swift.git', :tag => s.version.to_s }

  s.requires_arc = true
  s.platform     = :ios

  s.ios.deployment_target = '8.0'

  s.source_files = 'Sources/Core/**/*.swift'
  s.module_name = 'FacebookCore'
  s.pod_target_xcconfig = { 'ENABLE_TESTABILITY' => 'YES' }

  s.ios.dependency 'Bolts', '~> 1.8'
  s.ios.dependency 'FBSDKCoreKit', '~> 4.15'
end
