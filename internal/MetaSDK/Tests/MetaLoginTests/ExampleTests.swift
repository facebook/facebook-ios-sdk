// (c) Meta Platforms, Inc. and affiliates. Confidential and proprietary.

import XCTest
@testable import MetaLogin

class ExampleTests: XCTestCase {

    func testInternalMetaLoginMember() {
        XCTAssertTrue(
            ExampleClass().internalProperty,
            "Available for testing because of the testable import statement"
        )
    }
}
