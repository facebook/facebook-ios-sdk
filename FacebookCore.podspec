Pod::Spec.new do |s|
  s.name = "FacebookCore"
  s.version = "0.8.0"
  s.author = "Facebook"
  s.homepage = "https://developers.facebook.com/docs/swift"
  s.documentation_url = "https://developers.facebook.com/docs/swift/reference"
  s.license = { :type => "Facebook Platform License", :file => "LICENSE" }

  s.summary = "Official Facebook SDK in Swift to access Facebook Platform's core features."

  s.source = { :git => "https://github.com/facebook/facebook-swift-sdk.git", :tag => "v#{s.version}" }

  s.requires_arc = true
  s.platform = :ios

  s.swift_version = "5.0"

  s.ios.deployment_target = "8.0"

  s.source_files = "Sources/Core/**/*.swift"
  s.module_name = "FacebookCore"
  s.pod_target_xcconfig = { "ENABLE_TESTABILITY" => "YES" }

  s.ios.dependency "FBSDKCoreKit", "~> 5.0"
end
