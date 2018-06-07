Pod::Spec.new do |s|
  s.name         = 'FacebookLogin'
  s.version      = '0.3.1'
  s.author       = 'Facebook'
  s.homepage     = 'https://developers.facebook.com/docs/swift'
  s.documentation_url = 'https://developers.facebook.com/docs/swift/sdk-reference'
  s.license      = { :type => 'Facebook Platform License', :file => 'LICENSE' }

  s.summary      = "Official Facebook SDK in Swift to integrate with Facebook Login."

  s.source       = { :git => 'https://github.com/facebook/facebook-sdk-swift.git', :tag => s.version.to_s }

  s.requires_arc = true
  s.platform     = :ios

  s.ios.deployment_target = '8.0'

  s.source_files = 'Sources/Login/**/*.swift'
  s.exclude_files = 'Sources/Login/LoginManager.DefaultAudience.swift'
  s.module_name = 'FacebookLogin'

  s.ios.dependency 'FacebookCore', '~> 0.3.1'
  s.ios.dependency 'Bolts', '~> 1.8'
  s.ios.dependency 'FBSDKCoreKit', '~> 4.33'
  s.ios.dependency 'FBSDKLoginKit', '~> 4.33'
end
