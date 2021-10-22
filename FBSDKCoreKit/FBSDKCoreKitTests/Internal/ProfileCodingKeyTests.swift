/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import XCTest

final class ProfileCodingKeyTests: XCTestCase {
  func testRawValues() {
    XCTAssertEqual(ProfileCodingKey.userID.rawValue, "userID")
    XCTAssertEqual(ProfileCodingKey.firstName.rawValue, "firstName")
    XCTAssertEqual(ProfileCodingKey.middleName.rawValue, "middleName")
    XCTAssertEqual(ProfileCodingKey.lastName.rawValue, "lastName")
    XCTAssertEqual(ProfileCodingKey.name.rawValue, "name")
    XCTAssertEqual(ProfileCodingKey.linkURL.rawValue, "linkURL")
    XCTAssertEqual(ProfileCodingKey.refreshDate.rawValue, "refreshDate")
    XCTAssertEqual(ProfileCodingKey.imageURL.rawValue, "imageURL")
    XCTAssertEqual(ProfileCodingKey.email.rawValue, "email")
    XCTAssertEqual(ProfileCodingKey.friendIDs.rawValue, "friendIDs")
    XCTAssertEqual(ProfileCodingKey.isLimited.rawValue, "isLimited")
    XCTAssertEqual(ProfileCodingKey.birthday.rawValue, "birthday")
    XCTAssertEqual(ProfileCodingKey.ageRange.rawValue, "ageRange")
    XCTAssertEqual(ProfileCodingKey.hometown.rawValue, "hometown")
    XCTAssertEqual(ProfileCodingKey.location.rawValue, "location")
    XCTAssertEqual(ProfileCodingKey.gender.rawValue, "gender")
  }
}
