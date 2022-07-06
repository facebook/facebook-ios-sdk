/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

@testable import FBSDKGamingServicesKit
import FBSDKShareKit
import TestTools
import XCTest

final class GameRequestDialogTests: XCTestCase {
  // swiftlint:disable implicitly_unwrapped_optional
  var dialog: GameRequestDialog!
  var content: GameRequestContent!
  var delegate: TestGameRequestDialogDelegate!
  var bridgeAPIRequestOpener: TestBridgeAPIRequestOpener!
  var errorFactory: TestErrorFactory!
  var gameRequestURLProvider: TestGameRequestURLProvider.Type!
  var internalUtility: TestInternalUtility!
  var logger: FBSDKGamingServicesKitTests.TestLogger.Type!
  var settings: TestSettings!
  var shareValidator: TestShareUtility.Type!
  var utility: TestGamingUtility.Type!
  // swiftlint:enable implicitly_unwrapped_optional

  override func setUp() {
    super.setUp()

    content = GameRequestContent()
    delegate = TestGameRequestDialogDelegate()
    dialog = GameRequestDialog(content: content, delegate: delegate)

    bridgeAPIRequestOpener = TestBridgeAPIRequestOpener()
    errorFactory = TestErrorFactory()
    gameRequestURLProvider = TestGameRequestURLProvider.self
    internalUtility = TestInternalUtility()
    logger = FBSDKGamingServicesKitTests.TestLogger.self
    settings = TestSettings()
    shareValidator = TestShareUtility.self
    utility = TestGamingUtility.self

    dialog.setDependencies(
      .init(
        bridgeAPIRequestOpener: bridgeAPIRequestOpener,
        errorFactory: errorFactory,
        gameRequestURLProvider: gameRequestURLProvider,
        internalUtility: internalUtility,
        logger: logger,
        settings: settings,
        shareValidator: shareValidator,
        utility: utility
      )
    )
  }

  override func tearDown() {
    content = nil
    delegate = nil

    errorFactory = nil
    gameRequestURLProvider = nil
    internalUtility = nil
    logger = nil
    settings = nil
    shareValidator = nil
    bridgeAPIRequestOpener = nil
    utility = nil

    TestGameRequestURLProvider.reset()
    TestLogger.reset()
    TestShareUtility.reset()
    TestGamingUtility.reset()

    dialog = nil

    super.tearDown()
  }

  func testDefaultDependencies() throws {
    dialog.resetDependencies()
    let dependencies = try dialog.getDependencies()

    XCTAssertIdentical(
      dependencies.bridgeAPIRequestOpener,
      BridgeAPI.shared,
      .Dependencies.defaultDependency("the shared BridgeAPI", for: "bridge API request opener")
    )
    XCTAssertTrue(
      dependencies.errorFactory is ErrorFactory,
      .Dependencies.defaultDependency("a concrete error factory", for: "error factory")
    )
    XCTAssertIdentical(
      dependencies.gameRequestURLProvider as AnyObject,
      GameRequestURLProvider.self,
      .Dependencies.defaultDependency("GameRequestURLProvider", for: "game request URL provider")
    )
    XCTAssertIdentical(
      dependencies.internalUtility,
      InternalUtility.shared,
      .Dependencies.defaultDependency("the shared InternalUtility", for: "internal utility")
    )
    XCTAssertIdentical(
      dependencies.logger as AnyObject,
      Logger.self,
      .Dependencies.defaultDependency("Logger", for: "logger")
    )
    XCTAssertIdentical(
      dependencies.settings,
      Settings.shared,
      .Dependencies.defaultDependency("the shared Settings", for: "settings")
    )
    XCTAssertTrue(
      dependencies.shareValidator is _ShareUtility.Type,
      .Dependencies.defaultDependency("_ShareUtility", for: "share validator")
    )
    XCTAssertIdentical(
      dependencies.utility as AnyObject,
      Utility.self,
      .Dependencies.defaultDependency("Utility", for: "utility")
    )
  }

  func testCustomDependencies() throws {
    let dependencies = try dialog.getDependencies()

    XCTAssertIdentical(
      dependencies.bridgeAPIRequestOpener,
      bridgeAPIRequestOpener,
      .Dependencies.customDependency(for: "bridge API request opener")
    )
    XCTAssertIdentical(
      dependencies.errorFactory,
      errorFactory,
      .Dependencies.customDependency(for: "error factory")
    )
    XCTAssertIdentical(
      dependencies.gameRequestURLProvider as AnyObject,
      gameRequestURLProvider,
      .Dependencies.customDependency(for: "game request URL provider")
    )
    XCTAssertIdentical(
      dependencies.internalUtility,
      internalUtility,
      .Dependencies.customDependency(for: "internal utility")
    )
    XCTAssertIdentical(
      dependencies.logger as AnyObject,
      logger,
      .Dependencies.customDependency(for: "logger")
    )
    XCTAssertIdentical(
      dependencies.settings,
      settings,
      .Dependencies.customDependency(for: "settings")
    )
    XCTAssertIdentical(
      dependencies.shareValidator as AnyObject,
      shareValidator,
      .Dependencies.customDependency(for: "share validator")
    )
    XCTAssertIdentical(
      dependencies.utility as AnyObject,
      utility,
      .Dependencies.customDependency(for: "utility")
    )
  }
}

// MARK: - Assumptions

fileprivate extension String {
  enum Dependencies {
    static func defaultDependency(_ dependency: String, for type: String) -> String {
      "A GameRequestDialog instance uses \(dependency) as its \(type) dependency by default"
    }

    static func customDependency(for type: String) -> String {
      "A GameRequestDialog instance uses a custom \(type) dependency when provided"
    }
  }
}
