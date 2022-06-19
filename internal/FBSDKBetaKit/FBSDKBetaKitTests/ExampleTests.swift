// (c) Meta Platforms, Inc. and affiliates. Confidential and proprietary.

import XCTest
import FBSDKCoreKit
@testable import FBSDKBetaKit

class ExampleTests: XCTestCase {

    func testInternalCoreKitMethod() {
        XCTAssertFalse(
          FBSDKCoreKit.Settings.shared.isDataProcessingRestricted(),
            "Checks the internal core kit method `isDataProcessingRestricted` exposed via the bridging header"
        )
    }

    func testInternalBetaKitMember() {
        XCTAssertTrue(
            ExampleClass().internalProperty,
            "Available for testing because of the testable import statement"
        )
    }
}
