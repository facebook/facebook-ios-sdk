/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

@testable import FBSDKCoreKit

import TestTools
import XCTest

final class ErrorConfigurationTests: XCTestCase {

  let graphRequest = TestGraphRequest()
  let rawErrorCodeConfiguration = [
    [
      "name": "other",
      "items": [["code": 190, "subcodes": [459]]],
    ],
    [
      "name": "login",
      "items": [["code": 1, "subcodes": [12312]]],
      "recovery_message": "somemessage",
      "recovery_options": ["Yes", "No thanks"],
    ],
  ]

  func testErrorConfigurationDefaults() {
    let configuration = ErrorConfiguration(dictionary: nil)

    XCTAssertEqual(
      .transient,
      configuration.recoveryConfiguration(
        forCode: "1",
        subcode: nil,
        request: graphRequest
      )?.errorCategory
    )
    XCTAssertEqual(
      .transient,
      configuration.recoveryConfiguration(
        forCode: "1",
        subcode: "12312",
        request: graphRequest
      )?.errorCategory
    )
    XCTAssertEqual(
      .transient,
      configuration.recoveryConfiguration(
        forCode: "2",
        subcode: "*",
        request: graphRequest
      )?.errorCategory
    )
    XCTAssertNil(
      configuration.recoveryConfiguration(
        forCode: nil,
        subcode: nil,
        request: graphRequest
      )
    )
    XCTAssertEqual(
      .recoverable,
      configuration.recoveryConfiguration(
        forCode: "190",
        subcode: "459",
        request: graphRequest
      )?.errorCategory
    )
    XCTAssertEqual(
      .recoverable,
      configuration.recoveryConfiguration(
        forCode: "190",
        subcode: "300",
        request: graphRequest
      )?.errorCategory
    )
    XCTAssertEqual(
      .recoverable,
      configuration.recoveryConfiguration(
        forCode: "190",
        subcode: "458",
        request: graphRequest
      )?.errorCategory
    )
    XCTAssertEqual(
      .recoverable,
      configuration.recoveryConfiguration(
        forCode: "102",
        subcode: "*",
        request: graphRequest
      )?.errorCategory
    )
    XCTAssertNil(
      configuration.recoveryConfiguration(
        forCode: "104",
        subcode: nil,
        request: graphRequest
      )
    )
  }

  func testErrorConfigurationAdditonalArray() throws {
    let intermediaryConfiguration = ErrorConfiguration(dictionary: nil)
    intermediaryConfiguration.update(with: rawErrorCodeConfiguration)
    let data = NSKeyedArchiver.archivedData(
      withRootObject: intermediaryConfiguration)

    let configuration = try NSKeyedUnarchiver.unarchivedObject(
      ofClass: ErrorConfiguration.self, from: data
    )! // swiftlint:disable:this force_unwrapping
    XCTAssertEqual(
      .transient,
      configuration.recoveryConfiguration(
        forCode: "1",
        subcode: nil,
        request: graphRequest
      )?.errorCategory
    )
    XCTAssertEqual(
      .recoverable,
      configuration.recoveryConfiguration(
        forCode: "1",
        subcode: "12312",
        request: graphRequest
      )?.errorCategory
    )
    XCTAssertEqual(
      .transient,
      configuration.recoveryConfiguration(
        forCode: "2",
        subcode: "*",
        request: graphRequest
      )?.errorCategory
    )
    XCTAssertNil(
      configuration.recoveryConfiguration(
        forCode: nil,
        subcode: nil,
        request: graphRequest
      )
    )
    XCTAssertEqual(
      .other,
      configuration.recoveryConfiguration(
        forCode: "190",
        subcode: "459",
        request: graphRequest
      )?.errorCategory
    )
    XCTAssertEqual(
      GraphRequestError.recoverable,
      configuration.recoveryConfiguration(
        forCode: "190",
        subcode: "300",
        request: graphRequest
      )?.errorCategory
    )
    XCTAssertEqual(
      .recoverable,
      configuration.recoveryConfiguration(
        forCode: "102",
        subcode: "*",
        request: graphRequest
      )?.errorCategory
    )
  }

  func testParsingRandomName() {
    for _ in 0 ..< 100 {
      let array = [
        [
          "name": Fuzzer.random,
          "items": [["code": 190, "subcodes": [459]]],
        ],
        [
          "name": "login",
          "items": [["code": 1, "subcodes": [12312]]],
          "recovery_message": "somemessage",
          "recovery_options": ["Yes", "No thanks"],
        ],
      ]
      let configuration = ErrorConfiguration(dictionary: nil)
      configuration.update(with: array)
    }
  }

  func testParsingRandomSubcodes() {
    for _ in 0 ..< 100 {
      let array = [
        [
          "name": "other",
          "items": [["code": 190, "subcodes": [Fuzzer.random]]],
        ],
        [
          "name": "login",
          "items": [["code": 1, "subcodes": [Fuzzer.random]]],
          "recovery_message": "somemessage",
          "recovery_options": ["Yes", "No thanks"],
        ],
      ]
      let configuration = ErrorConfiguration(dictionary: nil)
      configuration.update(with: array)
    }
  }

  func testParsingRandomCodes() {
    for _ in 0 ..< 100 {
      let array = [
        [
          "name": "other",
          "items": [["code": Fuzzer.random, "subcodes": [459]]],
        ],
        [
          "name": "login",
          "items": [["code": Fuzzer.random, "subcodes": [12312]]],
          "recovery_message": "somemessage",
          "recovery_options": ["Yes", "No thanks"],
        ],
      ]
      let configuration = ErrorConfiguration(dictionary: nil)
      configuration.update(with: array)
    }
  }

  func testParsingRandomItemDictionaries() {
    for _ in 0 ..< 100 {
      let array = [
        [
          "name": "other",
          "items": Fuzzer.random,
        ],
        [
          "name": "login",
          "items": Fuzzer.random,
          "recovery_message": "somemessage",
          "recovery_options": ["Yes", "No thanks"],
        ],
      ]
      let configuration = ErrorConfiguration(dictionary: nil)
      configuration.update(with: array)
    }
  }

  func testParsingRandomRecoveryOptionsArray() {
    for _ in 0 ..< 100 {
      let array = [
        [
          "name": "other",
          "items": [["code": 190, "subcodes": [459]]],
        ],
        [
          "name": "login",
          "items": [["code": 1, "subcodes": [12312]]],
          "recovery_message": "somemessage",
          "recovery_options": [Fuzzer.random, Fuzzer.random],
        ],
      ]
      let configuration = ErrorConfiguration(dictionary: nil)
      configuration.update(with: array)
    }
  }

  func testParsingRandomRecoveryOptions() {
    for _ in 0 ..< 100 {
      let array = [
        [
          "name": "other",
          "items": [["code": 190, "subcodes": [459]]],
        ],
        [
          "name": "login",
          "items": [["code": 1, "subcodes": [12312]]],
          "recovery_message": "somemessage",
          "recovery_options": Fuzzer.random,
        ],
      ]
      let configuration = ErrorConfiguration(dictionary: nil)
      configuration.update(with: array)
    }
  }

  func testParsingRecoveryMessageWithoutOptions() {
    for _ in 0 ..< 100 {
      let array = [
        [
          "name": "other",
          "items": [["code": 190, "subcodes": [459]]],
        ],
        [
          "name": "login",
          "items": [["code": 1, "subcodes": [12312]]],
          "recovery_message": "somemessage",
          "recovery_options": ["Yes", "No thanks"],
        ],
      ]
      let configuration = ErrorConfiguration(dictionary: nil)
      configuration.update(with: array)
    }
  }

  func testParsingRandomEntries() {
    for _ in 0 ..< 100 {
      // swiftlint:disable:next force_cast
      let array = Fuzzer.randomize(json: rawErrorCodeConfiguration) as! [[String: Any]]
      let configuration = ErrorConfiguration(dictionary: nil)
      configuration.update(with: array)
    }
  }
}
