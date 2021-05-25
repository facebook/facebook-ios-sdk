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

#if !os(tvOS)

class FBSDKAEMAdvertiserSingleEntryRuleTests: XCTestCase {

  enum Keys {
      static let ruleOperator = "operator"
      static let ruleParamKey = "param_key"
      static let ruleStringValue = "string_value"
      static let ruleNumberValue = "number_value"
      static let ruleArrayValue = "array_value"
  }

  func testSecureCoding() {
    XCTAssertTrue(
      AEMAdvertiserSingleEntryRule.supportsSecureCoding,
      "AEM Advertiser Single Entry Rule should support secure coding"
    )
  }

  func testEncoding() throws {
    let coder = TestCoder()
    let entryRule = SampleAEMData.validAdvertiserSingleEntryRule
    entryRule.encode(with: coder)

    let ruleOperator = coder.encodedObject[Keys.ruleOperator] as? NSNumber
    XCTAssertEqual(
      ruleOperator?.intValue,
      entryRule.operator.rawValue,
      "Should encode the expected operator with the correct key"
    )
    XCTAssertEqual(
      coder.encodedObject[Keys.ruleParamKey] as? String,
      entryRule.paramKey,
      "Should encode the expected param_key with the correct key"
    )
    XCTAssertEqual(
      coder.encodedObject[Keys.ruleStringValue] as? String,
      entryRule.linguisticCondition,
      "Should encode the expected string_value with the correct key"
    )
    let numberValue = try XCTUnwrap(coder.encodedObject[Keys.ruleNumberValue] as? NSNumber)
    XCTAssertTrue(
      entryRule.numericalCondition?.isEqual(to: numberValue) == true,
      "Should encode the expected content with the correct key"
    )
    let arrayValue = try XCTUnwrap(coder.encodedObject[Keys.ruleArrayValue] as? NSArray)
    let expectedArrayValue = try XCTUnwrap(entryRule.arrayCondition as NSArray?)
    XCTAssertEqual(
      arrayValue,
      expectedArrayValue,
      "Should encode the expected array_value with the correct key"
    )
  }

  func testDecoding() {
    let decoder = TestCoder()
    _ = AEMAdvertiserSingleEntryRule(coder: decoder)

    XCTAssertEqual(
      decoder.decodedObject[Keys.ruleOperator] as? String,
      "decodeIntegerForKey",
      "Should decode the expected type for the operator key"
    )
    XCTAssertTrue(
      decoder.decodedObject[Keys.ruleParamKey] is NSString.Type,
      "Should decode the expected type for the param_key key"
    )
    XCTAssertTrue(
      decoder.decodedObject[Keys.ruleStringValue] is NSString.Type,
      "Should decode the expected type for the string_value key"
    )
    XCTAssertTrue(
      decoder.decodedObject[Keys.ruleNumberValue] is NSNumber.Type,
      "Should decode the expected type for the number_value key"
    )
    XCTAssertTrue(
      decoder.decodedObject[Keys.ruleArrayValue] is NSArray.Type,
      "Should decode the expected type for the array_value key"
    )
  }
}

#endif
