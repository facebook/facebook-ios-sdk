/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import FBSDKCoreKit_Basics
import XCTest

class LibAnalyzerTests: XCTestCase {

  func testGetMethodsTableFromPrefixesAndFrameworks() {
    let prefixes = ["FBSDK", "_FBSDK"]
    let frameworks = ["FBSDKCoreKit", "FBSDKLoginKit", "FBSDKShareKit", "FBSDKTVOSKit"]
    let result = LibAnalyzer.getMethodsTable(prefixes, frameworks: frameworks)
    XCTAssertFalse(result.isEmpty, "Should find at least one method declared in the provided frameworks")
  }

  func testSymbolicateCallstack() {
    let callstack = ["0x0000000109cbd02e", "0x0000000100cbd02e", "0x0000000111cbd04e"]
    let methodMapping = [
      "0x0109cbd02e": "-[FBSDKWebViewAppLinkResolver appLinkFromALData:destination:]+3110632",
      "0x0110cbd02e": "-[NSNib _instantiateWithOwner:options:topLevelObjects:] + 136",
      "0x0111cbd02e": "-[NSStoryboard instantiateControllerWithIdentifier:] + 236"
    ]
    var result = LibAnalyzer.symbolicateCallstack(callstack, methodMapping: methodMapping)

    XCTAssertNotNil(result, "Should return a value if both paramaters were passed")
    XCTAssertEqual(
      result,
      ["-[FBSDKWebViewAppLinkResolver appLinkFromALData:destination:]+3110632+0", "(2 DEV METHODS)"]
    )

    result = LibAnalyzer.symbolicateCallstack([], methodMapping: [:])
    XCTAssertNil(result, "method should return nil if either one or both parameters are empty")
  }
}
