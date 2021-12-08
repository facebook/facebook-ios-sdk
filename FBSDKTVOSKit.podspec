# Copyright (c) Facebook, Inc. and its affiliates.
# All rights reserved.
#
# This source code is licensed under the license found in the
# LICENSE file in the root directory of this source tree.

# Use the --use-libraries switch when pushing or linting this podspec

Pod::Spec.new do |s|

  s.name         = 'FBSDKTVOSKit'
  s.version      = '12.2.1'
  s.summary      = 'Official Facebook SDK for tvOS to access Facebook Platform with features like Login and Graph API.'

  s.description  = <<-DESC
                   The Facebook SDK for tvOS Kit framework provides Facebook Login with a confirmation code
                   to easily sign in users on Apple TV without using the remote.
                   See FBSDKCoreKit for additional functionality like Analytics and Graph API.
                   DESC

  s.homepage     = 'https://developers.facebook.com/docs/tvos'
  s.license      = {
    type: 'Facebook Platform License',
    text: <<-LICENSE
    Copyright (c) Facebook, Inc. and its affiliates. All rights reserved.

    You are hereby granted a non-exclusive, worldwide, royalty-free license to use,
    copy, modify, and distribute this software in source code or binary form for use
    in connection with the web services and APIs provided by Facebook.

    As with any software that integrates with the Facebook platform, your use of
    this software is subject to the Facebook Platform Policy
    [http://developers.facebook.com/policy/]. This copyright notice shall be
    included in all copies or substantial portions of the software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
    FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
    COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
    IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
    CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
    LICENSE
  }
  s.author       = 'Facebook'

  s.platform     = :tvos
  s.tvos.deployment_target = '10.0'
  s.swift_version = '5.0'

  s.source = { http: "https://github.com/facebook/facebook-ios-sdk/releases/download/v#{s.version}/FacebookSDK_Dynamic.xcframework.zip" }
  s.vendored_frameworks = 'XCFrameworks/FBSDKTVOSKit.xcframework'

  s.dependency 'FBSDKCoreKit_Basics', "#{s.version}"
  s.dependency 'FBSDKCoreKit', "#{s.version}"
  s.dependency 'FBSDKShareKit', "#{s.version}"
  s.dependency 'FBSDKLoginKit', "#{s.version}"
end
