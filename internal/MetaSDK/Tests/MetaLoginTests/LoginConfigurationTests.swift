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
    func testCreatingWithNoAppID() {
        let configuration = LoginConfiguration(
            permissions: ["public_profile"]
        )

        XCTAssertNil(configuration, "Should not be able to create configuration with no App ID")
    }

    func testCreatingWithNoFacebookAppID() {
        let configuration = LoginConfiguration(
            permissions: ["public_profile"],
            metaAppID: "some_meta_app_id"
        )

        XCTAssertNil(configuration, "Should not be able to create configuration with no FB App ID")
    }

    func testCreatingWithNoMetaAppID() {
        let configuration = LoginConfiguration(
            permissions: ["public_profile"],
            facebookAppID: "some_fb_app_id"
        )

        XCTAssertNil(configuration, "Should not be able to create configuration with no Meta App ID")
    }

    func testCreatingWithAppIDs() throws {
        let configuration = try XCTUnwrap(
            LoginConfiguration(
                facebookAppID: "some_fb_app_id",
                metaAppID: "some_meta_app_id"
            ),
            "Should be able to create a valid configuration with FB and meta App IDs"
        )
        XCTAssertEqual(configuration.permissions, [])
        XCTAssertEqual(configuration.facebookAppID, "some_fb_app_id")
        XCTAssertEqual(configuration.metaAppID, "some_meta_app_id")
    }

    func testCreatingWithPermissionsAndAppIDs() throws {
        let configuration = try XCTUnwrap(
            LoginConfiguration(
                permissions: ["public_profile"],
                facebookAppID: "some_fb_app_id",
                metaAppID: "some_meta_app_id"
            ),
            "Should be able to create a valid configuration with App IDs and permissions"
        )

        XCTAssertEqual(
            configuration.permissions,
            ["public_profile"],
            "A configuration should be created with provided permissions"
        )
    }
}
