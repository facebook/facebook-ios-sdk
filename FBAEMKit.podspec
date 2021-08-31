# Use the --use-libraries switch when pushing or linting this podspec

Pod::Spec.new do |s|

    s.name         = 'FBAEMKit'
    s.version      = '11.2.0'
    s.summary      = 'The kernal module for Facebook AEM solution'

    s.description  = <<-DESC
                     The Facebook SDK for iOS GamingKit framework provides:
                     * campaign level conversions from re-engagement ads.
                     DESC

    s.homepage     = 'https://developers.facebook.com/docs/ios/'
    s.license      = { type: 'Facebook Platform License', file: 'LICENSE' }
    s.author       = 'Facebook'

    s.platform     = :ios, :tvos
    s.ios.deployment_target = '9.0'
    s.tvos.deployment_target = '10.0'

    s.source       = {
      git: 'https://github.com/facebook/facebook-ios-sdk.git',
      tag: "v#{s.version}"
    }

    s.default_subspecs = 'AEM'
    s.swift_version = '5.0'
    s.pod_target_xcconfig = {
      'GCC_PREPROCESSOR_DEFINITIONS': '$(inherited) FBSDKCOCOAPODS=1',
      'DEFINES_MODULE': 'YES',
    }

    s.subspec 'AEM' do |ss|
      ss.dependency 'FBSDKCoreKit_Basics', "~> #{s.version}"
      ss.source_files = 'Sources/FBAEMKit/**/*.{h,m}'
    end
  end
