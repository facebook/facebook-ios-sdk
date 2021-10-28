/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

class AppLinkResolverRequestBuilderTests: XCTestCase {

  func testAsksForPhoneDataOnPhone() {
    let builder = AppLinkResolverRequestBuilder(userInterfaceIdiom: .phone)
    let request = builder.request(for: [])
    let askedForPhone = request.graphPath.contains("iphone")
    XCTAssertTrue(askedForPhone)
  }

  func testAsksForPadDataOnPad() {
    let builder = AppLinkResolverRequestBuilder(userInterfaceIdiom: .pad)
    let request = builder.request(for: [])
    let askedForPad = request.graphPath.contains("ipad")
    XCTAssertTrue(askedForPad)
  }
}
