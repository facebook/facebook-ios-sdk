// (c) Meta Platforms, Inc. and affiliates. Confidential and proprietary.

import XCTest
@testable import MetaLogin

class AuthWebViewTests: XCTestCase {
    var authWebView: AuthWebView!

    override func setUp() {
        super.setUp()
        authWebView = AuthWebView()
    }

    override func tearDown() {
        authWebView = nil
        super.tearDown()
    }
}
