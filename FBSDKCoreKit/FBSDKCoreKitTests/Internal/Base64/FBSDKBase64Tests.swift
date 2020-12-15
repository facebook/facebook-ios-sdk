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

import XCTest

class FBSDKBase64Tests: XCTestCase {

  func runTests(_ testsDict: [String: String]) {
    for (plainString, base64String) in testsDict {
      XCTAssertEqual(Base64.encode(plainString), base64String)
      XCTAssertEqual(Base64.decode(as: base64String), plainString)
    }
  }

  func testRFC4648TestVectors() {
    let testsDict = [
      "": "",
      "f": "Zg==",
      "fo": "Zm8=",
      "foo": "Zm9v",
      "foob": "Zm9vYg==",
      "fooba": "Zm9vYmE=",
      "foobar": "Zm9vYmFy",
    ]
    runTests(testsDict)
  }

  func testDecodeVariations() {
    XCTAssertEqual(Base64.decode(as: "aGVsbG8gd29ybGQh"), "hello world!")
    XCTAssertEqual(Base64.decode(as: "a  GVs\tb\r\nG8gd2\n9y\rbGQ h"), "hello world!")
    XCTAssertEqual(Base64.decode(as: "aGVsbG8gd29ybGQh"), "hello world!")
    XCTAssertEqual(Base64.decode(as: "aGVs#bG8*gd^29yb$GQh"), "hello world!")
  }

  func testEncodeDecode() {
    let testsDict = [
      "Hello World": "SGVsbG8gV29ybGQ=",
      "ABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890!%^&*(){}[]": "QUJDREVGR0hJSktMTU5PUFFSU1RVVldYWVoxMjM0NTY3ODkwISVeJiooKXt9W10=", // swiftlint:disable:this line_length
      "\n\t Line with control characters\r\n": "CgkgTGluZSB3aXRoIGNvbnRyb2wgY2hhcmFjdGVycw0K",
    ]
    runTests(testsDict)
  }

  func testBase64URLEncode() {
    let urlString = "https://www.example.com/some-path-with-dashes-in-it/"
    let encodedString = Base64.base64(fromBase64Url: urlString)
    XCTAssertEqual(encodedString, "https://www.example.com/some+path+with+dashes+in+it/")
  }
}
