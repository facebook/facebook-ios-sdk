Pod::Spec.new do |s|
    s.name              = 'FBSDKMarketingKit'
    s.version           = '5.13.1'
    s.summary           = 'Official Facebook SDK for iOS to set up Codeless Events'

    s.description  = <<-DESC
                   The Facebook SDK for iOS Marketing framework provides:
                   * Set up codeless events.
                   DESC

    s.homepage          = 'https://developers.facebook.com/docs/ios/'

    s.author            = 'Facebook'
    s.license           = { :type => 'Facebook Platform License', :text => <<-LICENSE
                              Copyright (c) 2014-present, Facebook, Inc. All rights reserved.

                              You are hereby granted a non-exclusive, worldwide, royalty-free license to use,
                              copy, modify, and distribute this software in source code or binary form for use
                              in connection with the web services and APIs provided by Facebook.

                              As with any software that integrates with the Facebook platform, your use of
                              this software is subject to the Facebook Developer Principles and Policies
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
    s.source            = { :http => "https://github.com/facebook/facebook-ios-sdk/releases/download/v#{s.version}/FBSDKMarketingKit.zip",
                            :type => :zip }
    s.source_files      = 'FBSDKMarketingKit.framework/**/*.h'
    s.public_header_files = 'FBSDKMarketingKit.framework/**/*.h'
    s.ios.vendored_frameworks = 'FBSDKMarketingKit.framework'

    s.ios.deployment_target = '8.0'

    s.ios.dependency 'FBSDKCoreKit', "~> 5.5"
end
