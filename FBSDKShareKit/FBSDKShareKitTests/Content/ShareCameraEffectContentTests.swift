/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

@testable import FBSDKShareKit

import FBSDKCoreKit
import TestTools
import XCTest

final class ShareCameraEffectContentTests: XCTestCase {
  // swiftlint:disable implicitly_unwrapped_optional
  var content: ShareCameraEffectContent!
  var internalUtility: TestInternalUtility!
  var errorFactory: TestErrorFactory!
  // swiftlint:enable implicitly_unwrapped_optional

  override func setUp() {
    super.setUp()

    internalUtility = TestInternalUtility()
    errorFactory = TestErrorFactory()

    ShareCameraEffectContent.setDependencies(
      .init(
        internalUtility: internalUtility,
        errorFactory: errorFactory
      )
    )

    content = ShareCameraEffectContent()
  }

  override func tearDown() {
    internalUtility = nil
    errorFactory = nil
    content = nil

    ShareCameraEffectContent.resetDependencies()

    super.tearDown()
  }

  func testDefaultDependencies() throws {
    ShareCameraEffectContent.resetDependencies()

    let dependencies = try ShareCameraEffectContent.getDependencies()
    XCTAssertIdentical(dependencies.internalUtility as AnyObject, InternalUtility.shared, .usesInternalUtilityByDefault)
    XCTAssertTrue(dependencies.errorFactory is ErrorFactory, .usesConcreteErrorFactoryByDefault)
  }

  func testCustomDependencies() throws {
    let dependencies = try ShareCameraEffectContent.getDependencies()
    XCTAssertIdentical(dependencies.internalUtility as AnyObject, internalUtility, .usesCustomInternalUtility)
    XCTAssertIdentical(dependencies.errorFactory, errorFactory, .usesCustomErrorFactory)
  }

  func testInvalidEffectIDs() throws {
    try ["a", "1a", "12345x67890"]
      .forEach { effectID in
        content.effectID = effectID
        XCTAssertThrowsError(
          try content.validate(options: []),
          "An effect ID (\(effectID)) must only contain digits"
        )
      }
  }

  func testValidEffectIDs() throws {
    try ["", "1", "123", "1234567890"]
      .forEach { effectID in
        content.effectID = effectID
        XCTAssertNoThrow(
          try content.validate(options: []),
          "An effect ID (\(effectID)) must only contain digits"
        )
      }
  }
}

// MARK: - Assumptions

fileprivate extension String {
  static let usesInternalUtilityByDefault = """
    The default internal utility dependency should be the shared InternalUtility
    """
  static let usesConcreteErrorFactoryByDefault = """
    The default error factory dependency should be a concrete ErrorFactory
    """
  static let usesCustomInternalUtility = "The internal utility dependency should be configurable"
  static let usesCustomErrorFactory = "The error factory dependency should be configurable"
}
