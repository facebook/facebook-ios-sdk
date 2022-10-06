/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !os(tvOS)

import FBSDKCoreKit

protocol ProfileCreating {

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
    isLimited: Bool
  ) -> Profile
}

#endif
