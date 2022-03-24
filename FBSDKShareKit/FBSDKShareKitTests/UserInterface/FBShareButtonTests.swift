/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

@testable import FBSDKShareKit
import TestTools
import XCTest

final class FBShareButtonTests: XCTestCase {

  // swiftlint:disable implicitly_unwrapped_optional
  var stringProvider: TestUserInterfaceStringProvider!
  // swiftlint:enable implicitly_unwrapped_optional

  override func setUp() {
    super.setUp()

    stringProvider = TestUserInterfaceStringProvider()
    FBShareButton.setDependencies(.init(stringProvider: stringProvider))
  }

  override func tearDown() {
    stringProvider = nil
    FBShareButton.resetDependencies()

    super.tearDown()
  }

  func testDefaultDependencies() throws {
    FBShareButton.resetDependencies()

    let dependencies = try FBShareButton.getDependencies()
    XCTAssertIdentical(dependencies.stringProvider as AnyObject, InternalUtility.shared, .usesInternalUtilityByDefault)
  }

  func testCustomDependencies() throws {
    let dependencies = try FBShareButton.getDependencies()
    XCTAssertIdentical(dependencies.stringProvider as AnyObject, stringProvider, .usesCustomStringProvider)
  }
}

// MARK: - Assumptions

fileprivate extension String {
  static let usesInternalUtilityByDefault = """
    The default string providing dependency should be the shared InternalUtility
    """
  static let usesCustomStringProvider = "The string providing dependency should be configurable"
}
