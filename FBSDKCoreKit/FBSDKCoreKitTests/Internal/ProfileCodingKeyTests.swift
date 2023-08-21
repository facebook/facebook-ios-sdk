/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

@testable import FBSDKCoreKit

import XCTest

final class ProfileCodingKeyTests: XCTestCase {
  func testRawValues() {
    XCTAssertEqual(Profile.CodingKeys.userID.rawValue, "userID")
    XCTAssertEqual(Profile.CodingKeys.firstName.rawValue, "firstName")
    XCTAssertEqual(Profile.CodingKeys.middleName.rawValue, "middleName")
    XCTAssertEqual(Profile.CodingKeys.lastName.rawValue, "lastName")
    XCTAssertEqual(Profile.CodingKeys.name.rawValue, "name")
    XCTAssertEqual(Profile.CodingKeys.linkURL.rawValue, "linkURL")
    XCTAssertEqual(Profile.CodingKeys.refreshDate.rawValue, "refreshDate")
    XCTAssertEqual(Profile.CodingKeys.imageURL.rawValue, "imageURL")
    XCTAssertEqual(Profile.CodingKeys.email.rawValue, "email")
    XCTAssertEqual(Profile.CodingKeys.friendIDs.rawValue, "friendIDs")
    XCTAssertEqual(Profile.CodingKeys.isLimited.rawValue, "isLimited")
    XCTAssertEqual(Profile.CodingKeys.birthday.rawValue, "birthday")
    XCTAssertEqual(Profile.CodingKeys.ageRange.rawValue, "ageRange")
    XCTAssertEqual(Profile.CodingKeys.hometown.rawValue, "hometown")
    XCTAssertEqual(Profile.CodingKeys.location.rawValue, "location")
    XCTAssertEqual(Profile.CodingKeys.gender.rawValue, "gender")
  }
}
