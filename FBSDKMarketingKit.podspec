Pod::Spec.new do |s|
    s.name              = "FBSDKMarketingKit"
    s.version           = "SDK_VERSION_TO_RELEASE"
    s.summary           = "Official Facebook SDK for iOS to set up Codeless Events"

    s.description  = <<-DESC
                   The Facebook SDK for iOS Marketing framework provides:
                   * Set up codeless events.
                   DESC

    s.homepage          = "https://developers.facebook.com/docs/ios/"

    s.author            = "Facebook"
    s.license           = { :type => "Facebook Platform License", :file => "LICENSE" }
    s.platform          = :ios
    s.source            = { :http => "https://origincache.facebook.com/developers/resources/?id=FacebookSDKs-iOS-SDK_VERSION_TO_RELEASE.zip" }
    s.source_files      = "FBSDKMarketingKit.framework/**/*.h"
    s.public_header_files = "FBSDKMarketingKit.framework/**/*.h"
    s.ios.vendored_frameworks = "FBSDKMarketingKit.framework"

    s.ios.deployment_target = "8.0"

    s.ios.dependency "Facebook-iOS-SDK/CoreKit", "~> SDK_VERSION_TO_RELEASE"
end
