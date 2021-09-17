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

import FacebookGamingServices
import XCTest

class FBSDKGamingContextTests: XCTestCase {

  func testCreating() throws {
    let context = try XCTUnwrap(GamingContext.createContext(withIdentifier: name, size: 2))
    XCTAssertNotNil(
      context,
      "Should be able to create a context with a valid identifier"
    )
    XCTAssertEqual(
      context.identifier,
      name,
      "Should be able to create a context with a valid identifier"
    )
    XCTAssertEqual(
      context.size,
      2,
      "Should be able to create a context with a valid size"
    )
  }

  func testCreatingWithSizeLessThanZero() throws {
    let context = try XCTUnwrap(GamingContext.createContext(withIdentifier: name, size: -2))
    XCTAssertNotNil(
      context,
      "Should be able to create a context with a valid identifier"
    )
    XCTAssertEqual(
      context.identifier,
      name,
      "Should be able to create a context with a valid identifier"
    )
    XCTAssertEqual(
      context.size,
      0,
      "Should not set size less than 0"
    )
  }

  func testCreatingWithEmptyIdentifier() {
    let context = GamingContext.createContext(withIdentifier: "", size: 2)
    XCTAssertNil(
      context,
      "Should not be able to create a context with a invalid identifier"
    )
  }
}
