# If you've made changes to the SDK (such as file paths), consider using `pod lib lint` to lint locally and then using the :path option in your Podfile

# If you're not making code changes but simply want to override aspects of this podspec (such as not including Bolts or the FBuserSettingsViewResources.bundle)
#  copy the file and use the :podspec option in your Podfile to point to the modified podspec.

Pod::Spec.new do |s|

  s.name         = "Facebook-iOS-SDK"
  s.version      = "3.19.0"
  s.summary      = "Official Facebook SDK for iOS to access Facebook Platform with features like Login, Share and Message Dialog, App Links, and Graph API"

  s.description  = <<-DESC
                   The Facebook SDK for iOS enables you to use Facebook's Platform such as:
                   * Facebook Login to easily sign in users.
                   * Sharing features like the Share or Message Dialog to grow your app.
                   * Simpler Graph API access to provide more social context.
                   DESC

  s.homepage     = "https://developers.facebook.com/docs/ios/"
  s.license      = { :type => "Apache License, Version 2.0", :file => "LICENSE" }

  s.author             = 'Facebook'

  s.platform     = :ios, "6.0"

  s.source       = { :git => "https://github.com/facebook/facebook-ios-sdk.git",
                     :tag => "sdk-version-3.19.0" ,
                     :submodules => true }

  s.source_files  =  "src/**/*.{h,m}"
  s.exclude_files = "src/**/*Tests.{h,m}", "src/tests/*.{h,m}", "src/*Test*/*.{h,m}"

  s.public_header_files = "src/*.h"

  s.header_dir = "FacebookSDK"

  s.resource  = "src/FBUserSettingsViewResources.bundle"

  s.weak_frameworks = "Accounts", "CoreLocation", "Social", "Security", "QuartzCore", "CoreGraphics", "UIKit", "Foundation", "AudioToolbox", "AdSupport"

  s.requires_arc = false

  # Note the prepare_command is not run against pods installed with the :path option (i.e., a local pod)
  s.prepare_command = "find src -name \\*.png | grep -v @ | grep -v '/tests/' | grep -v -- - | sed -e 's|\\(.*\\)/\\([a-zA-Z0-9]*\\).png|scripts/image_to_code.py -i \\1/\\2.png -c \\2 -o src|' | sh && find src -name \\*.wav | grep -v @ | grep -v -- - | sed -e 's|\\(.*\\)/\\([a-zA-Z0-9]*\\).wav|scripts/audio_to_code.py -i \\1/\\2.wav -c \\2 -o src|' | sh"

  s.dependency 'Bolts', '~> 1.0'

end
