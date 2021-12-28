/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

@testable import FacebookGamingServices
import XCTest

class ChooseContextContentTests: XCTestCase {

  let content = ChooseContextContent()

  func testCreatingWithoutSettingParameters() {
    XCTAssertEqual(
      content.filter,
      .none,
      "The default filter value should be .none"
    )
    XCTAssertEqual(
      content.minParticipants,
      0,
      "The default min participants value should be 0"
    )
    XCTAssertEqual(
      content.maxParticipants,
      0,
      "The default max participants value should be 0"
    )
  }

  func testValidatingWithInvalidMinAndMaxParticipants() {
    content.minParticipants = 2
    content.maxParticipants = 1

    do {
      try content.validate()
      XCTFail("Content with a min participants greater than max participant is invalid")
    } catch let error as NSError {
      XCTAssertEqual(error.domain, ErrorDomain)
      XCTAssertEqual(
        error.userInfo[ErrorDeveloperMessageKey] as? String,
        "The minimum size cannot be greater than the maximum size"
      )
    }
  }

  func testNameForFilterType() {
    XCTAssertEqual("NO_FILTER", ChooseContextContent.filtersName(forFilters: .none))
    XCTAssertEqual("NEW_PLAYERS_ONLY", ChooseContextContent.filtersName(forFilters: .newPlayersOnly))
    XCTAssertEqual("NEW_CONTEXT_ONLY", ChooseContextContent.filtersName(forFilters: .newContextOnly))
    XCTAssertEqual("INCLUDE_EXISTING_CHALLENGES", ChooseContextContent.filtersName(forFilters: .existingChallenges))
  }
}
