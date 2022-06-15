/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !os(tvOS)

import FBSDKCoreKit

/**
 Internal Type exposed to facilitate transition to Swift.
 API Subject to change or removal without warning. Do not use.

 @warning INTERNAL - DO NOT USE
 */
@objcMembers
@objc(FBSDKProfileFactory)
public final class _ProfileFactory: NSObject, ProfileCreating {

  // swiftlint:disable:next function_parameter_count
  public func createProfile(
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
      isLimited: isLimited
    )
  }
}

#endif
