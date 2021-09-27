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

@objcMembers
class TestBridgeAPIRequest: NSObject, BridgeAPIRequestProtocol {
  var actionID: String
  var methodName: String?
  var protocolType: FBSDKBridgeAPIProtocolType
  var `protocol`: BridgeAPIProtocol?
  var scheme: String

  let url: URL?

  init(url: URL?, protocolType: FBSDKBridgeAPIProtocolType = .native, scheme: String = "1") {
    self.url = url
    self.protocolType = protocolType
    self.scheme = scheme
    self.actionID = "1"
  }

  func copy(with zone: NSZone? = nil) -> Any {
    self
  }

  func requestURL() throws -> URL {
    guard let url = url else {
      throw FakeBridgeAPIRequestError(domain: "tests", code: 0, userInfo: [:])
    }
    return url
  }

  static func request(withURL url: URL?) -> TestBridgeAPIRequest {
    TestBridgeAPIRequest(url: url)
  }

  static func request(withURL url: URL, scheme: String) -> TestBridgeAPIRequest {
    TestBridgeAPIRequest(url: url, scheme: scheme)
  }
}

@objc
class FakeBridgeAPIRequestError: NSError {}
