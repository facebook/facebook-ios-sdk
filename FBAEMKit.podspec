# Copyright (c) Meta Platforms, Inc. and affiliates.
# All rights reserved.
#
# This source code is licensed under the license found in the
# LICENSE file in the root directory of this source tree.

# Use the --use-libraries switch when pushing or linting this podspec

Pod::Spec.new do |s|

    s.name         = 'FBAEMKit'
    s.version      = '17.4.0'
    s.summary      = 'The kernal module for Facebook AEM solution'

    s.description  = <<-DESC
                     The Facebook SDK for iOS GamingKit framework provides:
                     * campaign level conversions from re-engagement ads.
                     DESC

    s.homepage     = 'https://developers.facebook.com/docs/ios/'
    s.license      = {
      type: 'Facebook Platform License',
      text: <<-LICENSE
      Copyright (c) Meta Platforms, Inc. and affiliates. All rights reserved.

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

    s.platform     = :ios
    s.ios.deployment_target = '12.0'

    s.source = {
      http: "https://github.com/facebook/facebook-ios-sdk/releases/download/v#{s.version}/FacebookSDK_Dynamic.xcframework.zip",
      sha1: 'cc51c7121270855d49bac9ce391a8836d38e149f'
    }
    s.vendored_frameworks = 'XCFrameworks/FBAEMKit.xcframework'
    s.dependency 'FBSDKCoreKit_Basics', "#{s.version}"
  end
