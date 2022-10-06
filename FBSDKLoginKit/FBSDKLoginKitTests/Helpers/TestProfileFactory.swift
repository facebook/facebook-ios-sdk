/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

@testable import FBSDKLoginKit

import FBSDKCoreKit

final class TestProfileFactory: ProfileCreating {
  var capturedUserID: UserIdentifier?
  var capturedFirstName: String?
  var capturedMiddleName: String?
  var capturedLastName: String?
  var capturedName: String?
  var capturedLinkURL: URL?
  var capturedRefreshDate: Date?
  var capturedImageURL: URL?
  var capturedEmail: String?
  var capturedFriendIDs: [String]?
  var capturedBirthday: Date?
  var capturedAgeRange: UserAgeRange?
  var capturedHometown: Location?
  var capturedLocation: Location?
  var capturedGender: String?
  var capturedIsLimited = false
  private var stubbedProfile: Profile

  init(stubbedProfile: Profile) {
    self.stubbedProfile = stubbedProfile
  }

  func createProfile( // swiftlint:disable:this function_parameter_count
    userID: UserIdentifier,
    firstName: String?,
    middleName: String?,
    lastName: String?,
    name: String?,
    linkURL: URL?,
    refreshDate: Date?,
    imageURL: URL?,
    email: String?,
    friendIDs: [String]?,
    birthday: Date?,
    ageRange: UserAgeRange?,
    hometown: Location?,
    location: Location?,
    gender: String?,
    isLimited: Bool
  ) -> Profile {
    capturedUserID = userID
    capturedFirstName = firstName
    capturedMiddleName = middleName
    capturedLastName = lastName
    capturedName = name
    capturedLinkURL = linkURL
    capturedRefreshDate = refreshDate
    capturedImageURL = imageURL
    capturedEmail = email
    capturedFriendIDs = friendIDs
    capturedBirthday = birthday
    capturedAgeRange = ageRange
    capturedHometown = hometown
    capturedLocation = location
    capturedGender = gender
    capturedIsLimited = isLimited

    return stubbedProfile
  }
}
