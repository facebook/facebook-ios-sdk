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
public final class SampleUserProfiles: NSObject {

  public static let defaultName = "John Smith"
  public static let defaultImageURL = URL(string: "http://www.example.com/image.jpg")
  public static let defaultUserID = "123"

  public static var missingImageURL = createValid(imageURL: nil)
  public static var validLimited = createValid(isLimited: true)

  public static func createValid(userID: String) -> Profile {
    createValid(userID: userID, name: defaultName)
  }

  public static func createValid(isExpired: Bool) -> Profile {
    createValid(name: defaultName, isExpired: isExpired)
  }

  public static func createValid(
    userID: String = defaultUserID,
    name: String? = defaultName,
    imageURL url: URL? = defaultImageURL,
    isExpired: Bool = false,
    isLimited: Bool = false
  ) -> Profile {
    Profile(
      userID: userID,
      firstName: "John",
      middleName: "K",
      lastName: "Smith",
      name: name,
      linkURL: URL(string: "http://www.example.com"),
      refreshDate: isExpired ? .distantPast : .distantFuture,
      imageURL: url,
      email: "example@example.com",
      friendIDs: [
        "456",
        "789",
      ],
      birthday: Date(timeIntervalSince1970: 0),
      ageRange: UserAgeRange(from: ["min": 21]),
      hometown: Location(from: ["id": "112724962075996", "name": "Martinez, California"]),
      location: Location(from: ["id": "110843418940484", "name": "Seattle, Washington"]),
      gender: "male",
      isLimited: isLimited,
      permissions: [
        "public_profile",
        "user_link",
        "email",
        "user_friends",
        "user_birthday",
        "user_age_range",
        "user_hometown",
        "user_location",
        "user_gender",
      ]
    )
  }
}
