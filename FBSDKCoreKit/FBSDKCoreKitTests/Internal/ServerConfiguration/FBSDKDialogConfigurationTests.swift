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

class FBSDKDialogConfigurationTests: XCTestCase {

  let coder = TestCoder()
  let versions = ["1", "2", "3"]

  enum Keys {
    static let name = "name"
    static let url = "url"
    static let versions = "appVersions"
  }

  func testSecureCoding() {
    XCTAssertTrue(
      DialogConfiguration.supportsSecureCoding,
      "Should support secure coding"
    )
  }

  func testEncoding() {
    let dialog = DialogConfiguration(
      name: name,
      url: SampleUrls.valid,
      appVersions: versions
    )

    dialog?.encode(with: coder)

    XCTAssertEqual(
      coder.encodedObject[Keys.name] as? String,
      name,
      "Should encode the dialog name with the expected key"
    )
    XCTAssertEqual(
      coder.encodedObject[Keys.url] as? URL,
      SampleUrls.valid,
      "Should encode the dialog url with the expected key"
    )
    XCTAssertEqual(
      coder.encodedObject[Keys.versions] as? [String],
      versions,
      "Should encode the dialog app versions with the expected key"
    )
  }

  func testDecoding() {
    _ = DialogConfiguration(coder: coder)

    XCTAssertTrue(
      coder.decodedObject[Keys.name] is NSString.Type,
      "Should attempt to decode the name as a string"
    )
    XCTAssertTrue(
      coder.decodedObject[Keys.url] is NSURL.Type,
      "Should attempt to decode the url as a URL"
    )
    XCTAssertTrue(
      coder.decodedObject[Keys.versions] is NSSet,
      "Should attempt to decode the versions as a set of strings"
    )
  }
}
