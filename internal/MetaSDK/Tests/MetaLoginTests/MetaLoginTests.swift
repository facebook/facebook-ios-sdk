// (c) Meta Platforms, Inc. and affiliates. Confidential and proprietary.

@testable import MetaLogin
import XCTest

final class MetaLoginTests: XCTestCase {
    func testLogin() {
        var wasCalled = false

        MetaLogin().logIn { result in
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
