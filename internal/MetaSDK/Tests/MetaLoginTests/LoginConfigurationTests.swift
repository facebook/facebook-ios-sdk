/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

@testable import MetaLogin
import XCTest

final class LoginConfigurationTests: XCTestCase {
  var appConfigurationInquirer: TestAppConfigurationInquirer!

  override func setUp() {
    super.setUp()

    appConfigurationInquirer = TestAppConfigurationInquirer()
    appConfigurationInquirer.facebookAppID = "stubbed_facebook_app_id"
    appConfigurationInquirer.metaAppID = "stubbed_meta_app_id"
  }

  override func tearDown() {
    appConfigurationInquirer = nil

    super.tearDown()
  }

  func testDefaultDependencies() throws {
    var loginConfiguration = LoginConfiguration(permissions: [.publicProfile])
    loginConfiguration.resetDependencies()
    let dependencies = try loginConfiguration.getDependencies()

    XCTAssertEqual(
      dependencies.appConfigurationInquirer as? Bundle,
      Bundle.main,
      "A login configuration uses shared bundle object"
    )
  }

  func testCustomDependencies() throws {
    var loginConfiguration = LoginConfiguration(permissions: [.publicProfile])
    loginConfiguration.setDependencies(
      .init(appConfigurationInquirer: appConfigurationInquirer)
    )
    let dependencies = try loginConfiguration.getDependencies()

    XCTAssertIdentical(
      dependencies.appConfigurationInquirer as AnyObject,
      appConfigurationInquirer,
      "Should be set to custom app configuration inquirer"
    )
  }

  func testCreatingWithNoAppID() throws {
    var loginConfiguration = LoginConfiguration(permissions: [.publicProfile])
    loginConfiguration.setDependencies(
      .init(appConfigurationInquirer: appConfigurationInquirer)
    )

    XCTAssertEqual(
      loginConfiguration.facebookAppID,
      appConfigurationInquirer.facebookAppID,
      "A login configuration should use the default app configuration facebook app ID if not provided"
    )
    XCTAssertEqual(
      loginConfiguration.metaAppID,
      appConfigurationInquirer.metaAppID,
      "A login configuration should use the default app configuration meta app ID if not provided"
    )
  }

  func testCreatingWithNoFacebookAppID() {
    var loginConfiguration = LoginConfiguration(
      permissions: [.publicProfile],
      metaAppID: "some_meta_app_id"
    )
    loginConfiguration.setDependencies(
      .init(appConfigurationInquirer: appConfigurationInquirer)
    )

    XCTAssertEqual(
      loginConfiguration.facebookAppID,
      appConfigurationInquirer.facebookAppID,
      "A login configuration should use the default app configuration facebook app ID if not provided"
    )
    XCTAssertEqual(loginConfiguration.metaAppID, "some_meta_app_id", "Should set Meta App ID from parameters")
  }

  func testCreatingWithNoMetaAppID() {
    var loginConfiguration = LoginConfiguration(
      permissions: [.publicProfile],
      facebookAppID: "some_fb_app_id"
    )
    loginConfiguration.setDependencies(
      .init(appConfigurationInquirer: appConfigurationInquirer)
    )

    XCTAssertEqual(loginConfiguration.facebookAppID, "some_fb_app_id", "Should set Facebook App ID from parameters")
    XCTAssertEqual(
      loginConfiguration.metaAppID,
      appConfigurationInquirer.metaAppID,
      "A login configuration should use the default app configuration meta app ID if not provided"
    )
  }

  func testCreatingWithAppIDsAndNoPermissions() throws {
    var loginConfiguration = LoginConfiguration(
      facebookAppID: "some_fb_app_id",
      metaAppID: "some_meta_app_id"
    )
    loginConfiguration.setDependencies(
      .init(appConfigurationInquirer: appConfigurationInquirer)
    )

    XCTAssertEqual(loginConfiguration.permissions, [], "Should set permissions to empty set if not provided")
    XCTAssertEqual(loginConfiguration.facebookAppID, "some_fb_app_id", "Should set Facebook App ID from parameters")
    XCTAssertEqual(loginConfiguration.metaAppID, "some_meta_app_id", "Should set Meta App ID from parameters")
  }

  func testCreatingWithPermissionsAndAppIDs() throws {
    var loginConfiguration = LoginConfiguration(
      permissions: [.publicProfile],
      facebookAppID: "some_fb_app_id",
      metaAppID: "some_meta_app_id"
    )
    loginConfiguration.setDependencies(
      .init(appConfigurationInquirer: appConfigurationInquirer)
    )

    XCTAssertEqual(
      loginConfiguration.permissions,
      [.publicProfile],
      "A configuration should be created with provided permissions"
    )
    XCTAssertEqual(loginConfiguration.facebookAppID, "some_fb_app_id", "Should set Facebook App ID from parameters")
    XCTAssertEqual(loginConfiguration.metaAppID, "some_meta_app_id", "Should set Meta App ID from parameters")
  }

  func testCreatingWithNoDefaultAppIDs() throws {
    appConfigurationInquirer.metaAppID = nil
    appConfigurationInquirer.facebookAppID = nil

    var loginConfiguration = LoginConfiguration(
      permissions: [.publicProfile]
    )
    loginConfiguration.setDependencies(
      .init(appConfigurationInquirer: appConfigurationInquirer)
    )

    XCTAssertNil(
      loginConfiguration.metaAppID,
      "Should be nil if not provided at instantiation and does not exist in app configuration inquirer"
    )
    XCTAssertNil(
      loginConfiguration.facebookAppID,
      "Should be nil if not provided at instantiation and does not exist in app configuration inquirer"
    )
  }
}
