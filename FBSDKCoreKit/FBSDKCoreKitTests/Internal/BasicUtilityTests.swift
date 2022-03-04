/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

@testable import FBSDKCoreKit

import Foundation
import TestTools
import XCTest

final class BasicUtilityTests: XCTestCase {

  func testInvalidObjectToJSONString() throws {
    let invalidObject = TestErrorFactory()

    XCTAssertThrowsError(
      _ = try BasicUtility.jsonString(for: invalidObject) { object, _ in object },
      "An error should be thrown"
    ) { error in
      let nsError = error as NSError
      XCTAssertEqual(nsError.code, 2, "An invalid argument error code should be used")
      XCTAssertEqual(
        nsError.userInfo["com.facebook.sdk:FBSDKErrorArgumentNameKey"] as? String,
        "object",
        "The error name should refer to the object parameter"
      )
      XCTAssertIdentical(
        nsError.userInfo["com.facebook.sdk:FBSDKErrorArgumentValueKey"] as AnyObject,
        invalidObject,
        "The error value should contain the object argument"
      )
      XCTAssertEqual(
        nsError.userInfo["com.facebook.sdk:FBSDKErrorDeveloperMessageKey"] as? String,
        "Invalid object for JSON serialization.",
        "The error message should indicate that the object argument cannot be serialized to JSON"
      )
    }
  }

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
      "key3": "value 3 = foo",
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
