/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

@testable import MetaLogin
import XCTest

@available(iOS 13.0, *)
final class MetaLoginTests: XCTestCase {
    var authWebView: TestAuthWebView!
    var metaLogin: MetaLogin!

    override func setUp() {
        super.setUp()

        metaLogin = MetaLogin()
        authWebView = TestAuthWebView()
        metaLogin.setDependencies(
            .init(
                urlOpener: authWebView
            )
        )
    }

    override func tearDown() {
        metaLogin = nil
        authWebView = nil

        super.tearDown()
    }

    func testDefaultDependencies() throws {
        metaLogin.resetDependencies()
        let dependencies = try metaLogin.getDependencies()

        XCTAssertTrue(
            dependencies.urlOpener is AuthWebView,
            "A login manager uses a provided authentication web view"
        )
    }

    func testCustomDependencies() throws {
        let dependencies = try metaLogin.getDependencies()

        XCTAssertTrue(
            dependencies.urlOpener is TestAuthWebView,
            "Should be set to a custom authentication web view"
        )
    }

    func testLogin() throws {
        var wasCalled = false
        let loginConfiguration = try XCTUnwrap(
            LoginConfiguration(
                permissions: ["public_profile"],
                facebookAppID: "facebook_app_id",
                metaAppID: "some_meta_app_id"
            )
        )

        metaLogin.logIn(configuration: loginConfiguration) { result in
            switch result {
            case .success(let result):
                XCTAssertNotNil(result, "Should receive a success result from login")
            case .failure:
                XCTFail("Should not receive a failure result for login")
            }
            wasCalled = true
        }

        XCTAssertTrue(wasCalled, "Completion handler should be called synchronously")
    }
}
