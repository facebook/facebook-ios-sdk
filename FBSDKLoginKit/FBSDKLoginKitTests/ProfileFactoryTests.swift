/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import FBSDKLoginKit
import TestTools
import XCTest

class ProfileFactoryTests: XCTestCase {

  let expected = Profile(
    userID: SampleUserProfiles.valid.userID,
    firstName: SampleUserProfiles.valid.firstName,
    middleName: SampleUserProfiles.valid.middleName,
    lastName: SampleUserProfiles.valid.lastName,
    name: SampleUserProfiles.valid.name,
    linkURL: SampleUserProfiles.valid.linkURL,
    refreshDate: SampleUserProfiles.valid.refreshDate,
    imageURL: SampleUserProfiles.valid.imageURL,
    email: SampleUserProfiles.valid.email,
    friendIDs: SampleUserProfiles.valid.friendIDs,
    birthday: SampleUserProfiles.valid.birthday,
    ageRange: SampleUserProfiles.valid.ageRange,
    hometown: SampleUserProfiles.valid.hometown,
    location: SampleUserProfiles.valid.location,
    gender: SampleUserProfiles.valid.gender,
    isLimited: true
  )
  let factory = ProfileFactory()

  func testCreatingProfile() {
    let profile = factory.createProfile(
      userID: SampleUserProfiles.valid.userID,
      firstName: SampleUserProfiles.valid.firstName,
      middleName: SampleUserProfiles.valid.middleName,
      lastName: SampleUserProfiles.valid.lastName,
      name: SampleUserProfiles.valid.name,
      linkURL: SampleUserProfiles.valid.linkURL,
      refreshDate: SampleUserProfiles.valid.refreshDate,
      imageURL: SampleUserProfiles.valid.imageURL,
      email: SampleUserProfiles.valid.email,
      friendIDs: SampleUserProfiles.valid.friendIDs,
      birthday: SampleUserProfiles.valid.birthday,
      ageRange: SampleUserProfiles.valid.ageRange,
      hometown: SampleUserProfiles.valid.hometown,
      location: SampleUserProfiles.valid.location,
      gender: SampleUserProfiles.valid.gender,
      isLimited: true
    )
    XCTAssertEqual(profile.userID, expected.userID)
    XCTAssertEqual(profile.firstName, expected.firstName)
    XCTAssertEqual(profile.middleName, expected.middleName)
    XCTAssertEqual(profile.lastName, expected.lastName)
    XCTAssertEqual(profile.name, expected.name)
    XCTAssertEqual(profile.linkURL, expected.linkURL)
    XCTAssertEqual(profile.refreshDate, expected.refreshDate)
    XCTAssertEqual(profile.imageURL, expected.imageURL)
    XCTAssertEqual(profile.email, expected.email)
    XCTAssertEqual(profile.friendIDs, expected.friendIDs)
    XCTAssertEqual(profile.birthday, expected.birthday)
    XCTAssertEqual(profile.ageRange, expected.ageRange)
    XCTAssertEqual(profile.hometown, expected.hometown)
    XCTAssertEqual(profile.location, expected.location)
    XCTAssertEqual(profile.gender, expected.gender)
  }
}
