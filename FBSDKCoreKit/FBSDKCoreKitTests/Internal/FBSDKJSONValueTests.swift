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

class FBSDKJSONValueTests: XCTestCase {

  func testReturnsNilForBadInputs() throws {
    var error: NSError?
    XCTAssertNil(FBSDKCreateJSONFromString(nil, &error))
    XCTAssertNil(FBSDKCreateJSONFromString("THIS IS NOT JSON", &error))
    XCTAssertNil(FBSDKCreateJSONFromString("null", &error))

    // NSData should not be a valid entry in the dictionary to become JSON.
    let data = try XCTUnwrap("BLAH".data(using: .utf8))
    XCTAssertNil(FBSDKJSONValue(potentialJSONObject: ["id": data]))
  }

  func testArrayMatcher() {
    var error: NSError?
    let jsonValue = FBSDKCreateJSONFromString("[1, 2, 3, 4]", &error)

    var actual = [FBSDKJSONField]()
    jsonValue?.matchArray({ array in
      actual = array
    }, dictionary: nil)

    var num = 1
    for field in actual {
      XCTAssertEqual(field.rawObject as? Int, num)
      num += 1
    }
  }

  func testDictMatcher() {
    var error: NSError?
    let jsonValue = FBSDKCreateJSONFromString(#"{"id": 5}"#, &error)

    var actual = [String: FBSDKJSONField]()
    jsonValue?.matchArray(nil) { dictionary in
      actual = dictionary
    }

    XCTAssertEqual(actual["id"]?.rawObject as? Int, 5)
  }

  func testDictMatchersThatDontUseBlocks() {
    let jsonValue = FBSDKCreateJSONFromString(#"{"id": 5}"#, nil)
    XCTAssertEqual(jsonValue?.matchDictionaryOrNil()?["id"]?.rawObject as? Int, 5)
    XCTAssertEqual(jsonValue?.unsafe_matchDictionaryOrNil()?["id"] as? Int, 5)

    XCTAssertNil(jsonValue?.unsafe_matchArrayOrNil())
    XCTAssertNil(jsonValue?.matchArrayOrNil())
  }

  func testArrayMatchersThatDontUseBlocks() {
    let jsonValue = FBSDKCreateJSONFromString("[5]", nil)
    XCTAssertEqual(jsonValue?.matchArrayOrNil()?[0].rawObject as? Int, 5)
    XCTAssertEqual(jsonValue?.unsafe_matchArrayOrNil()?[0] as? Int, 5)

    XCTAssertNil(jsonValue?.unsafe_matchDictionaryOrNil())
    XCTAssertNil(jsonValue?.matchDictionaryOrNil())
  }

  // MARK: - FBSDKJSONField

  func testFieldMatchers() {
    var error: NSError?
    let jsonValue = FBSDKCreateJSONFromString("""
    [
      1,
      "hi",
      null,
      [1, 2, 3],
      {"key": "value"}
    ]
    """, &error)

    var actual = [FBSDKJSONField]()
    jsonValue?.matchArray({ array in
      actual = array
    }, dictionary: nil)

    let array = [1, 2, 3]
    let dict = ["key": "value"]
    XCTAssertEqual(actual[0].rawObject as? Int, 1)
    XCTAssertEqual(actual[0].numberOrNil() as? Int, 1)
    XCTAssertNil(actual[0].stringOrNil())

    XCTAssertEqual(actual[1].rawObject as? String, "hi")
    XCTAssertEqual(actual[1].stringOrNil(), "hi")
    XCTAssertNil(actual[1].numberOrNil())

    XCTAssertEqual(actual[2].rawObject as? NSNull, NSNull())
    XCTAssertEqual(actual[2].nullOrNil(), NSNull())
    XCTAssertNil(actual[2].stringOrNil())

    XCTAssertEqual(actual[3].rawObject as? [Int], array)
    XCTAssertTrue(actual[3].arrayOrNil()?.count == 3)
    XCTAssertNil(actual[3].stringOrNil())

    XCTAssertEqual(actual[4].rawObject as? [String: String], dict)
    XCTAssertEqual(actual[4].dictionaryOrNil()?.count, 1)
    XCTAssertNil(actual[4].stringOrNil())
  }

  func testMatchingDictionaryField() {
    var error: NSError?
    let jsonValue = FBSDKCreateJSONFromString(#"{"oh": "hi"}"#, &error)

    jsonValue?.matchArray({ _ in
      XCTFail("Should not match an array when none exists in the json string")
    }, dictionary: { dict in
      XCTAssertEqual(dict.keys.first, "oh")
      XCTAssertEqual(dict["oh"]?.rawObject as? String, "hi")
    })
  }
}
