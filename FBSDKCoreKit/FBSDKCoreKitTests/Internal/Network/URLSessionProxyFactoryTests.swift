/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import FBSDKCoreKit

class URLSessionProxyFactoryTests: XCTestCase, URLSessionDataDelegate {

  let factory = URLSessionProxyFactory()

  func testCreatingSessionProxy() {
    guard let proxy = factory.createSessionProxy(with: self, queue: OperationQueue.main) as? FBSDKURLSession else {
      return XCTFail("Session proxies should be created with the correct concrete type")
    }

    XCTAssertEqual(
      proxy.delegateQueue,
      OperationQueue.main,
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
