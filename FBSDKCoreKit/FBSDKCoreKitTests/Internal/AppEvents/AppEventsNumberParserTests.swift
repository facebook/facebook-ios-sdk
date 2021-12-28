/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

class AppEventsNumberParserTests: XCTestCase {
  func testGetNumberValueDefaultLocale() {
    let parser = AppEventsNumberParser(locale: Locale.current)
    let result = parser.parseNumber(from: "Price: $1,234.56; Buy 1 get 2!")
    let str = String(format: "%.2f", result.floatValue)
    XCTAssertEqual(str, "1234.56")
  }

  func testGetNumberValueWithLocaleFR() {
    let locale = Locale(identifier: "fr")
    let parser = AppEventsNumberParser(locale: locale)
    let result = parser.parseNumber(from: "Price: 1\u{202F}234,56; Buy 1 get 2!")
    let str = String(format: "%.2f", result.floatValue)
    XCTAssertEqual(str, "1234.56")
  }

  func testGetNumberValueWithLocaleIT() {
    let locale = Locale(identifier: "it")
    let parser = AppEventsNumberParser(locale: locale)
    let result = parser.parseNumber(from: "Price: 1.234,56; Buy 1 get 2!")
    let str = String(format: "%.2f", result.floatValue)
    XCTAssertEqual(str, "1234.56")
  }
}
