/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

@testable import FBSDKCoreKit
import XCTest

final class ProcessInfoTests: XCTestCase {
  // swiftlint:disable:next implicitly_unwrapped_optional
  var processInfo: ProcessInfo!
  lazy var currentOperatingSystemVersion = processInfo.operatingSystemVersion
  lazy var laterOperatingSystemVersion = OperatingSystemVersion(
    majorVersion: currentOperatingSystemVersion.majorVersion,
    minorVersion: currentOperatingSystemVersion.minorVersion,
    patchVersion: currentOperatingSystemVersion.patchVersion + 1
  )

  override func setUp() {
    super.setUp()
    processInfo = ProcessInfo()
  }

  override func tearDown() {
    processInfo = nil
    super.tearDown()
  }

  func testOperatingSystemAtLeastVersion() {
    XCTAssertEqual(
      processInfo.isOperatingSystemAtLeast(currentOperatingSystemVersion),
      processInfo.fb_isOperatingSystemAtLeast(currentOperatingSystemVersion),
      .isOperatingSystemAtLeastVersion
    )
    XCTAssertEqual(
      processInfo.isOperatingSystemAtLeast(laterOperatingSystemVersion),
      processInfo.fb_isOperatingSystemAtLeast(laterOperatingSystemVersion),
      .isOperatingSystemAtLeastVersion
    )
  }

  func testIsMacCatalystApp() {
    if #available(iOS 13, *) {
      XCTAssertEqual(
        processInfo.fb_isMacCatalystApp,
        processInfo.isMacCatalystApp,
        .isMacCatalystApp
      )
    } else {
      XCTAssertFalse(processInfo.fb_isMacCatalystApp, .isMacCatalystApp)
    }
  }
}

// MARK: - Assumptions

fileprivate extension String {
  static let isOperatingSystemAtLeastVersion = """
    A process info instance can compare operating system versions through an internal abstraction
    """
  static let isMacCatalystApp = """
    A process info instance indicates whether an app is a Mac Catalyst app through an internal abstraction
    """
}
