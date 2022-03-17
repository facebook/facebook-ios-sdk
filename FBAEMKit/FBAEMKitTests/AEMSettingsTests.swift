/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

@testable import FBAEMKit

import XCTest

final class AEMSettingsTests: XCTestCase {
  var bundle: TestBundle! // swiftlint:disable:this implicitly_unwrapped_optional

  override func setUp() {
    super.setUp()
    bundle = TestBundle()
    AEMSettings.setDependencies(.init(bundle: bundle))
  }

  override func tearDown() {
    AEMSettings.resetDependencies()
    bundle = nil
    super.tearDown()
  }

  func testDefaultDependencies() throws {
    AEMSettings.resetDependencies()
    let dependencies = try AEMSettings.getDependencies()
    XCTAssertIdentical(dependencies.bundle, Bundle.main, .usesMainBundle)
  }

  func testCustomDependencies() throws {
    let dependencies = try AEMSettings.getDependencies()
    XCTAssertIdentical(dependencies.bundle, bundle, .usesCustomBundle)
  }
}

// MARK: - Assumptions

fileprivate extension String {
  static let usesMainBundle = """
    The default bundle dependency should be the Main Bundle.
    """
  static let usesCustomBundle = "The bundle dependency should be configurable"
}
