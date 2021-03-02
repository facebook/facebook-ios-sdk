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

class GraphRequestFactoryTests: XCTestCase {

  let factory = GraphRequestFactory()

  func testCreatingRequest() {
    let request = factory.createGraphRequest(
      withGraphPath: "me",
      parameters: ["some": "thing"],
      tokenString: "foo",
      httpMethod: .get,
      flags: [.skipClientToken, .disableErrorRecovery]
    )
    guard let graphRequest = request as? GraphRequest else {
      return XCTFail("Should create a request of the correct concrete type")
    }

    XCTAssertEqual(
      graphRequest.graphPath,
      "me",
      "Should provide the graph path to the underlying type"
    )
    XCTAssertEqual(
      graphRequest.parameters as? [String: String],
      ["some": "thing"],
      "Should provide the parameters to the underlying type"
    )
    XCTAssertEqual(
      graphRequest.httpMethod, .get,
      "Should provide the HTTP method to the underlying type"
    )
    // TODO: Figure out why this is not consistently passing
//    XCTAssertEqual(
//      graphRequest.flags,
//      [.disableErrorRecovery],
//      "Should provide the flags to the underlying type"
//    )
  }
}
