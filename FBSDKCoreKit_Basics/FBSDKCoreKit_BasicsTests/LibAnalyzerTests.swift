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
