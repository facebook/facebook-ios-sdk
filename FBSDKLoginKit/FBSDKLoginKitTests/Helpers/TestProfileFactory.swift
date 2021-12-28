/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import FBSDKCoreKit
import Foundation

@objcMembers
public class TestProfileFactory: NSObject, ProfileCreating {

  public var capturedUserID: String?
  public var capturedFirstName: String?
  public var capturedMiddleName: String?
  public var capturedLastName: String?
  public var capturedName: String?
  public var capturedLinkURL: URL?
  public var capturedRefreshDate: Date?
  public var capturedImageURL: URL?
  public var capturedEmail: String?
  public var capturedFriendIDs: [String]?
  public var capturedBirthday: Date?
  public var capturedAgeRange: UserAgeRange?
  public var capturedHometown: Location?
  public var capturedLocation: Location?
  public var capturedGender: String?
  public var capturedIsLimited = false
  private var stubbedProfile: Profile

  public init(stubbedProfile: Profile) {
    self.stubbedProfile = stubbedProfile
  }

  public func createProfile( // swiftlint:disable:this function_parameter_count
    userID: String,
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
