/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

@testable import FBSDKCoreKit

import XCTest

@available(iOS 17.0, *)
final class ConvEncUtilsTest: XCTestCase {

  func testConversionDataEncryption() throws {
    let encrypted = ConvEncUtils.encConvString(
      publicKeyB64Url: "xDo68hsrKeoJBWIAPYO-K0UXbWT9b9TdIe_mraiLtBs",
      dataStr: "hello world"
    )
    XCTAssertNotNil(encrypted)
//    print("Ciphertext: \(String(describing: encrypted))")
  }
}
