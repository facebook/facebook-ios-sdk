/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

@testable import FBSDKCoreKit

import Foundation

final class MACARuleMatchingManagerTests: XCTestCase {
  let macaRuleMatchingManager = MACARuleMatchingManager()

  func testStringCompNotExistedDataValue() {
    XCTAssertFalse(
      macaRuleMatchingManager.stringComparison(
        variable: "card_type", values: ["eq": "platinum"], data: ["event": "CompleteRegistration"]
      ),
      "It should be considered as unmatched if data doesn't have the variable"
    )
  }

  func testStringCompContains() {
    XCTAssertTrue(
      macaRuleMatchingManager.stringComparison(
        variable: "URL",
        values: ["contains": "xxxxx"],
        data: ["event": "CompleteRegistration", "url": "www.xxxxx.com"]
      )
    )
  }

  func testStringCompIContains() {
    XCTAssertTrue(
      macaRuleMatchingManager.stringComparison(
        variable: "URL",
        values: ["i_contains": "xxxxx"],
        data: ["event": "CompleteRegistration", "url": "www.xxXxx.com"]
      )
    )
  }

  func testStringCompRegexMatch() {
    XCTAssertTrue(
      macaRuleMatchingManager.stringComparison(
        variable: "URL",
        values: ["regex_match": "eylea.us/support/?$|eylea.us/support/?"],
        data: ["event": "CompleteRegistration", "url": "eylea.us/support"]
      )
    )
  }

  func testStringCompEq() {
    XCTAssertTrue(
      macaRuleMatchingManager.stringComparison(
        variable: "event",
        values: ["eq": "CompleteRegistration"],
        data: ["event": "CompleteRegistration", "url": "eylea.us/support"]
      )
    )
  }

  func testStringCompNeq() {
    XCTAssertTrue(
      macaRuleMatchingManager.stringComparison(
        variable: "value",
        values: ["neq": "0"],
        data: ["value": "1"]
      )
    )
  }

  func testStringCompLt() {
    XCTAssertTrue(
      macaRuleMatchingManager.stringComparison(
        variable: "value",
        values: ["lt": "10"],
        data: ["value": "1"]
      )
    )
  }

  func testStringCompLte() {
    XCTAssertTrue(
      macaRuleMatchingManager.stringComparison(
        variable: "value",
        values: ["lte": "30"],
        data: ["value": "30"]
      )
    )
  }

  func testStringCompGt() {
    XCTAssertTrue(
      macaRuleMatchingManager.stringComparison(
        variable: "value",
        values: ["gt": "0"],
        data: ["value": "1"]
      )
    )
  }

  func testStringCompGte() {
    XCTAssertTrue(
      macaRuleMatchingManager.stringComparison(
        variable: "value",
        values: ["gte": "100"],
        data: ["value": "100"]
      )
    )
  }

  func testStringCompInvalidOp() {
    XCTAssertFalse(
      macaRuleMatchingManager.stringComparison(
        variable: "value",
        values: ["none": "0"],
        data: ["value": "1"]
      )
    )
  }

  func testRuleMatchNotExistedDataValue() {
    XCTAssertFalse(
      macaRuleMatchingManager.isMatchCCRule(
        #"{"and":[{"event":{"eq":"PageLoad"}}]}"#,
        data: [:]
      )
    )
  }

  func testRuleMatchContains() {
    XCTAssertTrue(
      macaRuleMatchingManager.isMatchCCRule(
        #"{"and":[{"event":{"eq":"Lead"}},{"or":[{"URL":{"contains":"xxxxx"}}]}]}"#,
        data: [
          "event": "Lead",
          "url": "www.xxxxx.com",
        ]
      )
    )
  }

  func testRuleMatchContainsNotValid() {
    XCTAssertFalse(
      macaRuleMatchingManager.isMatchCCRule(
        #"{"and":[{"event":{"eq":"Lead"}},{"or":[{"URL":{"contains":"xxxxx"}}]}]}"#,
        data: [
          "event": "Lead",
          "url": "www.xxXxx.com",
        ]
      )
    )
  }

  func testRuleMatchNotContains() {
    XCTAssertFalse(
      macaRuleMatchingManager.isMatchCCRule(
        #"{"and":[{"event":{"eq":"Lead"}},{"or":[{"URL":{"not_contains":"xxxxx"}}]}]}"#,
        data: [
          "event": "Lead",
          "url": "www.xxxxx.com",
        ]
      )
    )
  }

  func testRuleMatchIContains() {
    XCTAssertTrue(
      macaRuleMatchingManager.isMatchCCRule(
        #"{"and":[{"event":{"eq":"Lead"}},{"or":[{"URL":{"i_contains":"xxxxx"}}]}]}"#,
        data: [
          "event": "Lead",
          "url": "www.xxXxx.com",
        ]
      )
    )
  }

  func testRuleMatchINotContainsMatch() {
    XCTAssertTrue(
      macaRuleMatchingManager.isMatchCCRule(
        #"{"and":[{"event":{"eq":"Lead"}},{"or":[{"URL":{"i_not_contains":"xxxxx"}}]}]}"#,
        data: [
          "event": "Lead",
          "url": "www.xx.com",
        ]
      )
    )
  }

  func testRuleMatchINotContainsNotMatch() {
    XCTAssertFalse(
      macaRuleMatchingManager.isMatchCCRule(
        #"{"and":[{"event":{"eq":"Lead"}},{"or":[{"URL":{"i_not_contains":"xxxxx"}}]}]}"#,
        data: [
          "event": "Lead",
          "url": "www.xxXxxww.com",
        ]
      )
    )
  }

  func testRuleMatchStartsWith() {
    XCTAssertTrue(
      macaRuleMatchingManager.isMatchCCRule(
        #"{"and":[{"event":{"eq":"Lead"}},{"or":[{"URL":{"starts_with":"ww"}}]}]}"#,
        data: [
          "event": "Lead",
          "url": "www.xxXxxww.com",
        ]
      )
    )
  }

  func testRuleMatchIStartsWith() {
    XCTAssertTrue(
      macaRuleMatchingManager.isMatchCCRule(
        #"{"and":[{"event":{"eq":"Lead"}},{"or":[{"URL":{"i_starts_with":"ww"}}]}]}"#,
        data: [
          "event": "Lead",
          "url": "WWW.xxXxxww.com",
        ]
      )
    )
  }

  func testRuleMatchIStrEq() {
    XCTAssertTrue(
      macaRuleMatchingManager.isMatchCCRule(
        #"{"and":[{"event":{"eq":"Lead"}},{"or":[{"URL":{"i_str_eq":"WWW.xxXxxww.com"}}]}]}"#,
        data: [
          "event": "Lead",
          "url": "www.xxxxxww.com",
        ]
      )
    )
  }

  func testRuleMatchIStrNeq() {
    XCTAssertFalse(
      macaRuleMatchingManager.isMatchCCRule(
        #"{"and":[{"event":{"eq":"Lead"}},{"or":[{"URL":{"i_str_neq":"xxXxxww"}}]}]}"#,
        data: [
          "event": "Lead",
          "url": "XXXXXWW",
        ]
      )
    )
  }

  func testRuleMatchIn() {
    XCTAssertTrue(
      macaRuleMatchingManager.isMatchCCRule(
        #"{"and":[{"event":{"in":["fb_mobile_activate_app","fb_page_view","PixelInitialized","PageView"]}}]}"#,
        data: [
          "event": "fb_page_view",
          "url": "XXXXXWW",
        ]
      )
    )
    XCTAssertTrue(
      macaRuleMatchingManager.isMatchCCRule(
        #"{"and":[{"event":{"is_any":["fb_mobile_activate_app","fb_page_view","PixelInitialized","PageView"]}}]}"#,
        data: [
          "event": "fb_page_view",
          "url": "XXXXXWW",
        ]
      )
    )
  }

  func testRuleMatchIStrIn() {
    XCTAssertTrue(
      macaRuleMatchingManager.isMatchCCRule(
        #"{"and":[{"event":{"i_str_in":["fb_mobile_activate_app","fb_page_view","PixelInitialized","PageView"]}}]}"#,
        data: [
          "event": "FB_PAGE_VIEW",
          "url": "XXXXXWW",
        ]
      )
    )
    XCTAssertTrue(
      macaRuleMatchingManager.isMatchCCRule(
        #"{"and":[{"event":{"i_is_any":["fb_mobile_activate_app","fb_page_view","PixelInitialized","PageView"]}}]}"#,
        data: [
          "event": "PAGEView",
          "url": "XXXXXWW",
        ]
      )
    )
  }

  func testRuleMatchNotIn() {
    XCTAssertFalse(
      macaRuleMatchingManager.isMatchCCRule(
        #"{"and":[{"event":{"not_in":["fb_mobile_activate_app","fb_page_view","PixelInitialized","PageView"]}}]}"#,
        data: [
          "event": "fb_page_view",
          "url": "XXXXXWW",
        ]
      )
    )
    XCTAssertFalse(
      macaRuleMatchingManager.isMatchCCRule(
        #"{"and":[{"event":{"is_not_any":["fb_mobile_activate_app","fb_page_view","PixelInitialized","PageView"]}}]}"#,
        data: [
          "event": "fb_page_view",
          "url": "XXXXXWW",
        ]
      )
    )
  }

  func testRuleMatchIStrNotIn() {
    XCTAssertFalse(
      macaRuleMatchingManager.isMatchCCRule(
        #"{"and":[{"event":{"i_str_not_in":["fb_mobile_activate_app","fb_page_view","PageView"]}}]}"#,
        data: [
          "event": "FB_PAGE_VIEW",
          "url": "XXXXXWW",
        ]
      )
    )
    XCTAssertFalse(
      macaRuleMatchingManager.isMatchCCRule(
        #"{"and":[{"event":{"i_is_not_any":["fb_mobile_activate_app","fb_page_view","PageView"]}}]}"#,
        data: [
          "event": "PAGEView",
          "url": "XXXXXWW",
        ]
      )
    )
  }

  func testRuleMatchRegexMatch() {
    XCTAssertTrue(
      macaRuleMatchingManager.isMatchCCRule(
        #"{"and":[{"or":[{"URL":{"regex_match":"eylea.us/support/?$|eylea.us/support/?"}}]}]}"#,
        data: [
          "event": "Lead",
          "url": "eylea.us/support",
        ]
      )
    )
  }

  func testRuleMatchRegexNotMatch() {
    XCTAssertFalse(
      macaRuleMatchingManager.isMatchCCRule(
        #"{"and":[{"or":[{"URL":{"regex_match":"eylea.us/support/?$|eylea.us/support/?"}}]}]}"#,
        data: [
          "event": "Lead",
          "url": "eylea.us.support",
        ]
      )
    )
  }

  func testRuleMatchExists() {
    XCTAssertTrue(
      macaRuleMatchingManager.isMatchCCRule(
        #"{"and":[{"url":{"exists": true}}]}"#,
        data: [
          "event": "PageLoad",
          "url": "eylea.us.support",
        ]
      )
    )
    XCTAssertFalse(
      macaRuleMatchingManager.isMatchCCRule(
        #"{"and":[{"url":{"exists": false}}]}"#,
        data: [
          "event": "PageLoad",
          "url": "eylea.us.support",
        ]
      )
    )
    XCTAssertFalse(
      macaRuleMatchingManager.isMatchCCRule(
        #"{"and":[{"product":{"exists": false}}]}"#,
        data: [
          "event": "PageLoad",
          "product": "eylea.us.support",
        ]
      )
    )
    XCTAssertTrue(
      macaRuleMatchingManager.isMatchCCRule(
        #"{"and":[{"product":{"exists": false}}]}"#,
        data: [
          "event": "PageLoad",
          "url": "eylea.us.support",
        ]
      )
    )
  }

  func testRuleMatchEq() {
    XCTAssertTrue(
      macaRuleMatchingManager.isMatchCCRule(
        #"{"and":[{"event":{"eq":"PageLoad"}}]}"#,
        data: ["event": "PageLoad"]
      )
    )
    XCTAssertTrue(
      macaRuleMatchingManager.isMatchCCRule(
        #"{"and":[{"event":{"=":"PageLoad"}}]}"#,
        data: ["event": "PageLoad"]
      )
    )
    XCTAssertTrue(
      macaRuleMatchingManager.isMatchCCRule(
        #"{"and":[{"event":{"==":"PageLoad"}}]}"#,
        data: ["event": "PageLoad"]
      )
    )
  }

  func testRuleMatchNeq() {
    XCTAssertFalse(
      macaRuleMatchingManager.isMatchCCRule(
        #"{"and":[{"event":{"neq":"PageLoad"}}]}"#,
        data: ["event": "PageLoad"]
      )
    )
    XCTAssertFalse(
      macaRuleMatchingManager.isMatchCCRule(
        #"{"and":[{"event":{"ne":"PageLoad"}}]}"#,
        data: ["event": "PageLoad"]
      )
    )
    XCTAssertFalse(
      macaRuleMatchingManager.isMatchCCRule(
        #"{"and":[{"event":{"!=":"PageLoad"}}]}"#,
        data: ["event": "PageLoad"]
      )
    )
  }

  func testRuleMatchLt() {
    XCTAssertTrue(
      macaRuleMatchingManager.isMatchCCRule(
        #"{"and":[{"value":{"lt":"30"}}]}"#,
        data: ["value": 1]
      )
    )
    XCTAssertTrue(
      macaRuleMatchingManager.isMatchCCRule(
        #"{"and":[{"value":{"<":"30"}}]}"#,
        data: ["value": 1]
      )
    )
  }

  func testRuleMatchLte() {
    XCTAssertTrue(
      macaRuleMatchingManager.isMatchCCRule(
        #"{"and":[{"value":{"lte":"30"}}]}"#,
        data: ["value": "30"]
      )
    )
    XCTAssertTrue(
      macaRuleMatchingManager.isMatchCCRule(
        #"{"and":[{"value":{"le":"30"}}]}"#,
        data: ["value": "30"]
      )
    )
    XCTAssertTrue(
      macaRuleMatchingManager.isMatchCCRule(
        #"{"and":[{"value":{"<=":"30"}}]}"#,
        data: ["value": "30"]
      )
    )
  }

  func testRuleMatchGt() {
    XCTAssertTrue(
      macaRuleMatchingManager.isMatchCCRule(
        #"{"and":[{"value":{"gt":"30"}}]}"#,
        data: ["value": 31]
      )
    )
    XCTAssertTrue(
      macaRuleMatchingManager.isMatchCCRule(
        #"{"and":[{"value":{">":"30"}}]}"#,
        data: ["value": 31]
      )
    )
  }

  func testRuleMatchGte() {
    XCTAssertTrue(
      macaRuleMatchingManager.isMatchCCRule(
        #"{"and":[{"value":{"gte":"30"}}]}"#,
        data: ["value": "30"]
      )
    )
    XCTAssertTrue(
      macaRuleMatchingManager.isMatchCCRule(
        #"{"and":[{"value":{"ge":"30"}}]}"#,
        data: ["value": "30"]
      )
    )
    XCTAssertTrue(
      macaRuleMatchingManager.isMatchCCRule(
        #"{"and":[{"value":{">=":"30"}}]}"#,
        data: ["value": "30"]
      )
    )
  }
}
