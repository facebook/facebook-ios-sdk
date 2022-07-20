// (c) Meta Platforms, Inc. and affiliates. Confidential and proprietary.

@testable import MetaLogin
import XCTest

@available(iOS 13.0, *)
class AuthWebViewTests: XCTestCase {
    var authWebView: AuthWebView!
    var webAuthSessionFactory: TestWebAuthenticationSessionFactory!
    var authSession: TestWebAuthenticationSession!

    override func setUp() {
        super.setUp()
        authWebView = AuthWebView()
        authSession = TestWebAuthenticationSession()
        webAuthSessionFactory = TestWebAuthenticationSessionFactory(stubbedSession: authSession)

        authWebView.setDependencies(
            .init(webAuthenticationSessionFactory: webAuthSessionFactory)
        )
    }

    override func tearDown() {
        authWebView = nil
        authSession = nil
        webAuthSessionFactory = nil
        super.tearDown()
    }

    func testDefaultDependencies() throws {
        authWebView.resetDependencies()
        let dependencies = try authWebView.getDependencies()

        XCTAssertTrue(
            dependencies.webAuthenticationSessionFactory is WebAuthenticationSessionFactory,
            "A web authentication view uses a provided web authentication session factory."
        )
    }

    func testCustomDependencies() throws {
        let dependencies = try authWebView.getDependencies()
        XCTAssertIdentical(
            dependencies.webAuthenticationSessionFactory as AnyObject,
            webAuthSessionFactory,
            "Should be set to custom web authentication session factory"
        )
    }
}
