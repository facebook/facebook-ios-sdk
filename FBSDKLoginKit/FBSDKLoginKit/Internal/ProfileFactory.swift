/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import FBSDKCoreKit

final class ProfileFactory: NSObject, ProfileCreating {

  // swiftlint:disable:next function_parameter_count
  func createProfile(
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
    permissions: Set<String>?,
    isLimited: Bool
  ) -> Profile {
    Profile(
      userID: userID,
      firstName: firstName,
      middleName: middleName,
      lastName: lastName,
      name: name,
      linkURL: linkURL,
      refreshDate: refreshDate,
      imageURL: imageURL,
      email: email,
      friendIDs: friendIDs,
      birthday: birthday,
      ageRange: ageRange,
      hometown: hometown,
      location: location,
      gender: gender,
      isLimited: isLimited,
      permissions: permissions
    )
  }
}
