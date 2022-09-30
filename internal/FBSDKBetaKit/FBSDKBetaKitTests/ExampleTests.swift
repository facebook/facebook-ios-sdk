// (c) Meta Platforms, Inc. and affiliates. Confidential and proprietary.

@testable import FBSDKBetaKit
import FBSDKCoreKit
import XCTest

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
