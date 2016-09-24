Pod::Spec.new do |s|
  s.name         = 'FacebookShare'
  s.version      = '0.2.0'
  s.author       = 'Facebook'
  s.homepage     = 'https://developers.facebook.com/docs/swift'
  s.documentation_url = 'https://developers.facebook.com/docs/swift/reference'
  s.license      = { :type => 'Facebook Platform License', :file => 'LICENSE' }

  s.summary      = "Official Facebook SDK in Swift to access Facebook Platform's Sharing Features."
  s.description  = <<-DESC
                   The Facebook SDK for iOS ShareKit framework provides:
                   * Share content with Share Dialog and Message Dialog.
                   * Send Game Requests or App Invites to grow your app.
                   * Publish content and open graph stories with the Graph API.
                   DESC

  s.source       = { :git => 'https://github.com/facebook/facebook-sdk-swift.git', :tag => s.version.to_s }

  s.requires_arc = true
  s.platform     = :ios

  s.ios.deployment_target = '8.0'

  s.source_files = 'Sources/Share/**/*.swift'
  s.module_name = 'FacebookShare'

  s.ios.dependency 'FacebookCore', '~> 0.2'
  s.ios.dependency 'Bolts', '~> 1.8'
  s.ios.dependency 'FBSDKCoreKit', '~> 4.15'
  s.ios.dependency 'FBSDKShareKit', '~> 4.15'
end
