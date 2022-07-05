/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

@testable import FBSDKLoginKit

import TestTools
import XCTest

final class ProfileFactoryTests: XCTestCase {

  // swiftlint:disable implicitly_unwrapped_optional
  var sampleProfile: Profile!
  var factory: ProfileFactory!
  // swiftlint:enable implicitly_unwrapped_optional

  override func setUp() {
    super.setUp()

    sampleProfile = SampleUserProfiles.createValid(isLimited: true)
    factory = ProfileFactory()
  }

  override func tearDown() {
    sampleProfile = nil
    factory = nil

    super.tearDown()
  }

  func testCreatingProfile() {
    let profile = factory.createProfile(
      userID: sampleProfile.userID,
      firstName: sampleProfile.firstName,
      middleName: sampleProfile.middleName,
      lastName: sampleProfile.lastName,
      name: sampleProfile.name,
      linkURL: sampleProfile.linkURL,
      refreshDate: sampleProfile.refreshDate,
      imageURL: sampleProfile.imageURL,
      email: sampleProfile.email,
      friendIDs: sampleProfile.friendIDs,
      birthday: sampleProfile.birthday,
      ageRange: sampleProfile.ageRange,
      hometown: sampleProfile.hometown,
      location: sampleProfile.location,
      gender: sampleProfile.gender,
      isLimited: true
    )

    XCTAssertEqual(profile.userID, sampleProfile.userID)
    XCTAssertEqual(profile.firstName, sampleProfile.firstName)
    XCTAssertEqual(profile.middleName, sampleProfile.middleName)
    XCTAssertEqual(profile.lastName, sampleProfile.lastName)
    XCTAssertEqual(profile.name, sampleProfile.name)
    XCTAssertEqual(profile.linkURL, sampleProfile.linkURL)
    XCTAssertEqual(profile.refreshDate, sampleProfile.refreshDate)
    XCTAssertEqual(profile.imageURL, sampleProfile.imageURL)
    XCTAssertEqual(profile.email, sampleProfile.email)
    XCTAssertEqual(profile.friendIDs, sampleProfile.friendIDs)
    XCTAssertEqual(profile.birthday, sampleProfile.birthday)
    XCTAssertEqual(profile.ageRange, sampleProfile.ageRange)
    XCTAssertEqual(profile.hometown, sampleProfile.hometown)
    XCTAssertEqual(profile.location, sampleProfile.location)
    XCTAssertEqual(profile.gender, sampleProfile.gender)
  }
}
