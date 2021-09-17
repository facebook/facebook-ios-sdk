// Copyright (c) 2014-present, Facebook, Inc. All rights reserved.
//
// You are hereby granted a non-exclusive, worldwide, royalty-free license to use,
// copy, modify, and distribute this software in source code or binary form for use
// in connection with the web services and APIs provided by Facebook.
//
// As with any software that integrates with the Facebook platform, your use of
// this software is subject to the Facebook Developer Principles and Policies
// [http://developers.facebook.com/policy/]. This copyright notice shall be
// included in all copies or substantial portions of the software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
// FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
// COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
// IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
// CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

import TestTools

@objcMembers
class TestServerConfigurationProvider: NSObject, ServerConfigurationProviding, ServerConfigurationLoading {

  var capturedCompletionBlock: ServerConfigurationBlock?
  var secondCapturedCompletionBlock: ServerConfigurationBlock?
  var loadServerConfigurationWasCalled = false
  var stubbedRequestToLoadServerConfiguration: GraphRequest?
  var stubbedServerConfiguration: ServerConfiguration
  var requestToLoadConfigurationCallWasCalled = false
  var didRetrieveCachedServerConfiguration = false

  init(configuration: ServerConfiguration = ServerConfigurationFixtures.defaultConfig) {
    stubbedServerConfiguration = configuration
  }

  func cachedServerConfiguration() -> ServerConfiguration {
    didRetrieveCachedServerConfiguration = true
    return stubbedServerConfiguration
  }

  func loadServerConfiguration(completionBlock: ServerConfigurationBlock?) {
    loadServerConfigurationWasCalled = true
    guard capturedCompletionBlock == nil else {
      secondCapturedCompletionBlock = completionBlock
      return
    }

    capturedCompletionBlock = completionBlock
  }

  func reset() {
    requestToLoadConfigurationCallWasCalled = false
    loadServerConfigurationWasCalled = false
    capturedCompletionBlock = nil
    secondCapturedCompletionBlock = nil
  }

  func processLoadRequestResponse(_ result: Any, error: Error?, appID: String) {
  }

  func request(toLoadServerConfiguration appID: String) -> GraphRequest? {
    requestToLoadConfigurationCallWasCalled = true
    return stubbedRequestToLoadServerConfiguration
  }
}
