/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

@testable import FBSDKCoreKit

import XCTest

final class DialogConfigurationMapBuilderTests: XCTestCase {

  enum Keys {
    static let name = "name"
    static let url = "url"
    static let versions = "versions"
  }

  enum Values {
    static let empty = ""
    static let urlString = "http://example.com"
    static let url = URL(string: urlString)! // swiftlint:disable:this force_unwrapping
  }

  let builder = DialogConfigurationMapBuilder()

  func testBuildingWithEmptyRawConfigurations() {
    XCTAssertTrue(
      builder.buildDialogConfigurationMap(from: []).isEmpty,
      "Should not build configurations from an empty array"
    )
  }

  func testBuildingWithEmptyNameKey() {
    let rawConfigurations = [[Keys.name: ""]]
    XCTAssertTrue(
      builder.buildDialogConfigurationMap(from: rawConfigurations).isEmpty,
      "Should not build a configuration for a dialog with an empty name"
    )
  }

  func testBuildingWithValidNameMissingUrlMissingVersions() {
    let rawConfigurations = [[Keys.name: name]]
    XCTAssertTrue(
      builder.buildDialogConfigurationMap(from: rawConfigurations).isEmpty,
      "Should not build a configuration for a dialog with a missing URL"
    )
  }

  func testBuildingWithValidNameEmptyUrlMissingVersions() {
    let rawConfigurations = [
      [
        Keys.name: name,
        Keys.url: Values.empty,
      ],
    ]
    XCTAssertTrue(
      builder.buildDialogConfigurationMap(from: rawConfigurations).isEmpty,
      "Should not build a configuration for a dialog with an empty URL"
    )
  }

  func testBuildingWithValidNameValidUrlMissingVersions() {
    let rawConfigurations = [
      [
        Keys.name: name,
        Keys.url: Values.urlString,
      ],
    ]
    XCTAssertTrue(
      builder.buildDialogConfigurationMap(from: rawConfigurations).isEmpty,
      "Should not build a configuration for a dialog with missing versions"
    )
  }

  func testBuildingWithValidNameValidUrlEmptyVersions() {
    let rawConfigurations = [
      [
        Keys.name: name,
        Keys.url: Values.urlString,
        Keys.versions: [],
      ],
    ]
    XCTAssertTrue(
      builder.buildDialogConfigurationMap(from: rawConfigurations).isEmpty,
      "Should not build a configuration for a dialog with empty versions"
    )
  }

  func testBuildingWithValidNameValidUrlValidVersions() throws {
    let rawConfigurations = [
      [
        Keys.name: name,
        Keys.url: Values.urlString,
        Keys.versions: ["1", "2"],
      ],
    ]
    let configurationMap = builder.buildDialogConfigurationMap(from: rawConfigurations)

    let actual = try XCTUnwrap(configurationMap[name], "Should map dialog configurations to their name")
    let expected = DialogConfiguration(name: name, url: Values.url, appVersions: ["1", "2"])
    assertEqualConfigurations(actual, expected)
  }

  func testBuildingWithDuplicateConfigurations() throws {
    let configuration = DialogConfiguration(name: name, url: Values.url, appVersions: ["1", "2"])
    let otherConfiguration = DialogConfiguration(
      name: name,
      url: Values.url.appendingPathComponent("foo"),
      appVersions: [3]
    )

    let rawConfigurations = [
      [
        Keys.name: configuration.name,
        Keys.url: configuration.url.absoluteString,
        Keys.versions: configuration.appVersions,
      ],
      [
        Keys.name: otherConfiguration.name,
        Keys.url: otherConfiguration.url.absoluteString,
        Keys.versions: otherConfiguration.appVersions,
      ],
    ]
    let configurationMap = builder.buildDialogConfigurationMap(from: rawConfigurations)

    let actual = try XCTUnwrap(configurationMap[name], "Should map dialog configurations to their name")
    assertEqualConfigurations(actual, otherConfiguration)
  }

  // MARK: - Helpers

  func assertEqualConfigurations(
    _ actual: DialogConfiguration,
    _ expected: DialogConfiguration,
    _ file: StaticString = #file,
    _ line: UInt = #line
  ) {
    XCTAssertEqual(actual.name, expected.name, file: file, line: line)
    XCTAssertEqual(actual.url, expected.url, file: file, line: line)
    if let actualStringVersions = actual.appVersions as? [String], // swiftlint:disable:next indentation_width
       let expectedStringVersions = expected.appVersions as? [String] {
      XCTAssertEqual(
        actualStringVersions,
        expectedStringVersions,
        file: file,
        line: line
      )
    } else if let actualIntegerVersions = actual.appVersions as? [Int], // swiftlint:disable:next indentation_width
              let expectedIntegerVersions = expected.appVersions as? [Int] {
      XCTAssertEqual(
        actualIntegerVersions,
        expectedIntegerVersions,
        file: file,
        line: line
      )
    } else {
      XCTFail(
        "Dialog configuration versions should be an array of either strings or integers",
        file: file,
        line: line
      )
    }
  }
}
