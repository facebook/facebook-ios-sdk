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

class BasicUtilityTests: XCTestCase {

  func testJSONString() throws {
    let urlString = "https://www.facebook.com"
    let url = URL(string: urlString)
    let dictionary = ["url": url]

    let jsonString = try BasicUtility.jsonString(for: dictionary, invalidObjectHandler: nil)
    XCTAssertEqual(jsonString, #"{"url":"https:\/\/www.facebook.com"}"#)
    let decoded = try XCTUnwrap(try BasicUtility.object(forJSONString: jsonString) as? [String: Any])

    XCTAssertEqual(Array(decoded.keys), ["url"])
    XCTAssertEqual(decoded["url"] as? String, urlString)
  }

  func testConvertRequestValue() throws {
    let result1 = BasicUtility.convertRequestValue(1)
    XCTAssertEqual(result1 as? String, "1")

    let value2 = try XCTUnwrap(URL(string: "https://test"))
    let result2 = BasicUtility.convertRequestValue(value2)
    XCTAssertEqual(result2 as? String, "https://test")

    let value3 = [String]()
    let result3 = BasicUtility.convertRequestValue(value3)
    XCTAssertTrue(result3 is [String])
  }

  func testQueryString() throws {
    let urlString = "http://example.com/path/to/page.html?key1&key2=value2&key3=value+3%20%3D%20foo#fragment=go"
    let urlQueryString = try XCTUnwrap(URL(string: urlString)?.query)
    let dictionary = BasicUtility.dictionary(withQueryString: urlQueryString)
    let expectedDictionary = [
      "key1": "",
      "key2": "value2",
      "key3": "value 3 = foo"
    ]
    XCTAssertEqual(dictionary, expectedDictionary)
    let queryString = try BasicUtility.queryString(with: dictionary, invalidObjectHandler: nil)
    let expectedQueryString = "key1=&key2=value2&key3=value%203%20%3D%20foo"
    XCTAssertEqual(queryString, expectedQueryString)

    // test repetition now that the query string has been cleaned and normalized
    let dictionary2 = BasicUtility.dictionary(withQueryString: queryString)
    XCTAssertEqual(dictionary2, expectedDictionary)
    let queryString2 = try BasicUtility.queryString(with: dictionary2, invalidObjectHandler: nil)
    XCTAssertEqual(queryString2, expectedQueryString)
  }

  func testURLEncode() {
    let value = "test this \"string\u{2019}s\" encoded value"
    let encoded = BasicUtility.urlEncode(value)
    XCTAssertEqual(encoded, "test%20this%20%22string%E2%80%99s%22%20encoded%20value")
    let decoded = BasicUtility.urlDecode(encoded)
    XCTAssertEqual(decoded, value)
  }

  func testURLEncodeSpecialCharacters() {
    let value = ":!*();@/&?#[]+$,='%\"\u{2019}"
    let encoded = BasicUtility.urlEncode(value)
    XCTAssertEqual(encoded, "%3A%21%2A%28%29%3B%40%2F%26%3F%23%5B%5D%2B%24%2C%3D%27%25%22%E2%80%99")
    let decoded = BasicUtility.urlDecode(encoded)
    XCTAssertEqual(decoded, value)
  }
}
