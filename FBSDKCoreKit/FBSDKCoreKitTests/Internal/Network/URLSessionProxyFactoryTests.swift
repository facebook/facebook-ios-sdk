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

import FBSDKCoreKit

class URLSessionProxyFactoryTests: XCTestCase, URLSessionDataDelegate {

  let factory = URLSessionProxyFactory()

  func testCreatingSessionProxy() {
    guard let proxy = factory.createSessionProxy(with: self, queue: OperationQueue.main) as? FBSDKURLSession else {
      return XCTFail("Session proxies should be created with the correct concrete type")
    }

    XCTAssertEqual(
      proxy.delegateQueue, OperationQueue.main,
      "The provided proxy Should use the operation queue it was created with"
    )
    XCTAssertTrue(
      proxy.delegate === self,
      "The provided proxy should use the delegate it was created with"
    )
  }

  func testCreatingSessionProxies() {
    let proxy = factory.createSessionProxy(with: self, queue: OperationQueue.main)
    let proxy2 = factory.createSessionProxy(with: self, queue: OperationQueue.main)

    XCTAssertFalse(
      proxy === proxy2,
      "Session proxies should be unique"
    )
  }

}
