# (c) Meta Platforms, Inc. and affiliates. Confidential and proprietary.

Pod::Spec.new do |s|
    s.name              = 'BetaKit'
    s.module_name       = 'FBSDKBetaKit'
    s.version           = '0.0.1'
    s.summary           = 'Facebook BetaKit for iOS to set up AAM'

    s.description  = <<-DESC
                   The Facebook SDK for iOS Beta framework provides:
                   * Set up Automatic Advanced Matching.
                   DESC

    s.homepage     = 'https://developers.facebook.com/docs/ios/'
    s.author            = 'Facebook'
    s.license           = { :type => 'Facebook Platform License', :text => <<-LICENSE
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
    s.platform          = :ios
    s.source            = { :http => "https://www.marsmobile.com/beta/FBSDKBetaKit.#{s.version}.zip",
                            :type => :zip }
    s.source_files      = 'FBSDKBetaKit.framework/**/*.h'
    s.public_header_files = 'FBSDKBetaKit.framework/**/*.h'
    s.ios.vendored_frameworks = 'FBSDKBetaKit.framework'

    s.ios.deployment_target = '8.0'

    s.ios.dependency 'FBSDKCoreKit', "~> 5.2.3"
end
