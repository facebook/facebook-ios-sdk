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
final class AuthWebViewTests: XCTestCase {
    var authWebView: AuthWebView!
    var webAuthSessionFactory: TestWebAuthenticationSessionFactory!
    var authSession: TestWebAuthenticationSession!
    var presentationContextProvider: TestWebAuthenticationSessionPresentationContextProvider!
    let sampleURL = SampleURLs.valid
    let sampleCallbackURLScheme = "metalogin"

    override func setUp() {
        super.setUp()
        authWebView = AuthWebView()
        presentationContextProvider = TestWebAuthenticationSessionPresentationContextProvider()
        authSession = TestWebAuthenticationSession(stubbedPresentationContextProvider: presentationContextProvider)
        webAuthSessionFactory = TestWebAuthenticationSessionFactory(stubbedSession: authSession)
        authWebView.setDependencies(
            .init(
                webAuthenticationSessionFactory: webAuthSessionFactory,
                presentationContextProvider: presentationContextProvider)
        )
    }

    override func tearDown() {
        authWebView = nil
        authSession = nil
        webAuthSessionFactory = nil
        presentationContextProvider = nil
        super.tearDown()
    }

    func testDefaultDependencies() throws {
        authWebView.resetDependencies()
        let dependencies = try authWebView.getDependencies()

        XCTAssertTrue(
            dependencies.webAuthenticationSessionFactory is WebAuthenticationSessionFactory,
            "A web authentication view uses a provided web authentication session factory"
        )
        XCTAssertTrue(
            dependencies.presentationContextProvider is WebAuthenticationSessionPresentationContextProvider,
            "A web authentication view uses a provided presentation context provider"
        )
    }

    func testCustomDependencies() throws {
        let dependencies = try authWebView.getDependencies()

        XCTAssertTrue(
            dependencies.webAuthenticationSessionFactory is TestWebAuthenticationSessionFactory,
            "Should be set to custom web authentication session factory"
        )
        XCTAssertTrue(
            dependencies.presentationContextProvider is TestWebAuthenticationSessionPresentationContextProvider,
            "Should be set to custom presentation context provider"
        )
    }

    func testOpenURL() throws {
        var capturedResult: Result<URL, Error>?
        authWebView.openURL(
            url: sampleURL,
            callbackURLScheme: sampleCallbackURLScheme
        ) { result in
            capturedResult = result
        }

        XCTAssertEqual(
            webAuthSessionFactory.capturedURL,
            sampleURL,
            "Should pass sample url to the authentication session"
        )
        XCTAssertEqual(
            webAuthSessionFactory.capturedCallbackURLScheme,
            sampleCallbackURLScheme,
            "Should pass sample callback url scheme to the authentication session"
        )

        let url = SampleURLs.valid(path: "foo")
        webAuthSessionFactory.capturedCompletionHandler?(.success(url))
        XCTAssertEqual(
            try capturedResult?.get(),
            url,
            "Should invoke the completion handler with the expected result"
        )
        XCTAssertTrue(authSession.startWasCalled, "Authentication session starts when openURL is called")
        XCTAssertIdentical(
            authSession.presentationContextProvider,
            presentationContextProvider,
            "Should set the presentation context provider on the authentication session"
        )
    }
}
