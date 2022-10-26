/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import Foundation

/**
 Represents an immutable Facebook profile.

 This class provides a global current profile instance to more easily
 add social context to your application. When the profile changes, a notification is
 posted so that you can update relevant parts of your UI. It is persisted to `UserDefaults.standard`.

 Typically, you will want to set `enableUpdatesOnAccessTokenChange` to `true` so that
 it automatically observes changes to `AccessToken.current`.

 You can use this class to build your own `ProfilePictureView` or in place of typical requests to the `/me` endpoint.
 */
@objcMembers
@objc(FBSDKProfile)
public final class Profile: NSObject {

  /// The user identifier.
  public let userID: UserIdentifier

  /// The user's first name.
  public let firstName: String?

  /// The user's middle name.
  public let middleName: String?

  /// The user's last name.
  public let lastName: String?

  /// The user's complete name.
  public let name: String?

  /**
   A URL to the user's profile.

   - Important: This field will only be populated if your user has granted your application the `user_link` permission.

   Consider using `AppLinkResolver` to resolve this URL to an app link in order to link directly to
   the user's profile in the Facebook app.
   */
  public let linkURL: URL?

  /// The last time the profile data was fetched.
  public let refreshDate: Date

  /// A URL to use for fetching the user's profile image.
  public let imageURL: URL?

  /**
   The user's email address.

   - Important: This field will only be populated if your user has granted your application the `email` permission.
   */
  public let email: String?

  /**
   A list of identifiers of the user's friends.

   - Important: This field will only be populated if your user has granted your application
     the `user_friends` permission.
   */
  public let friendIDs: [UserIdentifier]?

  /**
   The user's birthday.

   - Important: This field will only be populated if your user has granted your application
   the `user_birthday` permission.
   */
  public let birthday: Date?

  /**
   The user's age range.

   - Important: This field will only be populated if your user has granted your application
   the `user_age_range` permission.
   */
  public let ageRange: UserAgeRange?

  /**
   The user's hometown.

   - Important: This field will only be populated if your user has granted your application
   the `user_hometown` permission.
   */
  public let hometown: Location?

  /**
   The user's location.

   - Important: This field will only be populated if your user has granted your application
   the `user_location` permission.
   */
  public let location: Location?

  /**
   The user's gender.

   - Important: This field will only be populated if your user has granted your application
   the `user_gender` permission.
   */
  public let gender: String?

  let isLimited: Bool

  // swiftlint:disable:next identifier_name
  static var _current: Profile?

  /**
   Indicates whether this type will automatically observe access token changes
   (via `AccessTokenDidChange` notifications).

   If observing changes, this class will issue a Graph request for public profile data when the current token's user
   identifier differs from the current profile. You can observe profile changes via `ProfileDidChange` notifications
   to handle an updated profile.

   - Note: If the current access token is cleared, the current profile instance remains available. It's also possible
   for `current` to return `nil` until the data is fetched.
   */
  public static var isUpdatedWithAccessTokenChange = false {
    didSet {
      if isUpdatedWithAccessTokenChange {
        Self.notificationCenter?.fb_addObserver(
          self,
          selector: #selector(observeAccessTokenChange(_:)),
          name: .AccessTokenDidChange,
          object: nil
        )
      } else {
        Self.notificationCenter?.fb_removeObserver(self)
      }
    }
  }

  /**
   Creates a new profile.

   - Parameters:
     - userID: The user's identifier.
     - firstName: The user's first name. Defaults to `nil`.
     - middleName: The user's middle name. Defaults to `nil`.
     - lastName: The user's last name. Defaults to `nil`.
     - name: The user's complete name. Defaults to `nil`.
     - linkURL: The link for the profile. Defaults to `nil`.
     - refreshDate: The date the profile was fetched. Defaults to the time of instantiation.
   */
  @objc(initWithUserID:firstName:middleName:lastName:name:linkURL:refreshDate:)
  public convenience init(
    userID: UserIdentifier,
    firstName: String?,
    middleName: String?,
    lastName: String?,
    name: String?,
    linkURL: URL?,
    refreshDate: Date?
  ) {
    self.init(
      userID: userID,
      firstName: firstName,
      middleName: middleName,
      lastName: lastName,
      name: name,
      linkURL: linkURL,
      refreshDate: refreshDate,
      imageURL: nil,
      email: nil,
      friendIDs: nil,
      birthday: nil,
      ageRange: nil,
      hometown: nil,
      location: nil,
      gender: nil,
      isLimited: false
    )
  }

  // swiftlint:disable:next swiftlint_disable_without_this_or_next
  // swiftlint:disable line_length
  // swiftformat:disable blankLinesBetweenScopes

  /**
   Creates a new profile.

   - Parameters:
     - userID: The user's identifier. Defaults to `nil`.
     - firstName: The user's first name. Defaults to `nil`.
     - middleName: The user's middle name. Defaults to `nil`.
     - lastName: The user's last name. Defaults to `nil`.
     - name: The user's complete name. Defaults to `nil`.
     - linkURL: The link for this profile. Defaults to `nil`.
     - refreshDate: The date this profile was fetched. Defaults to the time of instantiation.
     - imageURL: A URL to use for fetching a user's profile image.
     - email: The user's email address. Defaults to `nil`.
     - friendIDs: A list of identifiers for the user's friends. Defaults to `nil`.
     - birthday: The user's birthday. Defaults to `nil`.
     - ageRange: The user's age range. Defaults to `nil`.
     - hometown: The user's hometown. Defaults to `nil`.
     - location: The user's location. Defaults to `nil`.
     - gender: The user's gender. Defaults to `nil`.
   */
  @objc(initWithUserID:firstName:middleName:lastName:name:linkURL:refreshDate:imageURL:email:friendIDs:birthday:ageRange:hometown:location:gender:)
  public convenience init(
    userID: UserIdentifier,
    firstName: String? = nil,
    middleName: String? = nil,
    lastName: String? = nil,
    name: String? = nil,
    linkURL: URL? = nil,
    refreshDate: Date? = Date(),
    imageURL: URL? = nil,
    email: String? = nil,
    friendIDs: [UserIdentifier]? = nil,
    birthday: Date? = nil,
    ageRange: UserAgeRange? = nil,
    hometown: Location? = nil,
    location: Location? = nil,
    gender: String? = nil
  ) {
    self.init(
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
      isLimited: false
    )
  }

  /**
   Creates a new profile.

   - Parameters:
     - userID: The user's identifier. Defaults to `nil`.
     - firstName: The user's first name. Defaults to `nil`.
     - middleName: The user's middle name. Defaults to `nil`.
     - lastName: The user's last name. Defaults to `nil`.
     - name: The user's complete name. Defaults to `nil`.
     - linkURL: The link for the profile. Defaults to `nil`.
     - refreshDate: The date the profile was fetched. Defaults to the time of instantiation.
     - imageURL: A URL to use for fetching the user's profile image Defaults to `nil`.
     - email: The user's email address. Defaults to `nil`.
     - friendIDs: A list of identifiers for the user's friends. Defaults to `nil`.
     - birthday: The user's birthday. Defaults to `nil`.
     - ageRange: The user's age range. Defaults to `nil`.
     - hometown: The user's hometown. Defaults to `nil`.
     - location: The user's location. Defaults to `nil`.
     - gender: The user's gender. Defaults to `nil`.
     - isLimited: Indicates whether the information provided is incomplete in some way.
       When `true`, `loadCurrentProfile(completion:):` will assume the profile is incomplete and disregard
       any cached profile. Defaults to `false`.
   */
  @objc(initWithUserID:firstName:middleName:lastName:name:linkURL:refreshDate:imageURL:email:friendIDs:birthday:ageRange:hometown:location:gender:isLimited:)
  public init(
    userID: UserIdentifier,
    firstName: String?,
    middleName: String?,
    lastName: String?,
    name: String?,
    linkURL: URL?,
    refreshDate: Date?,
    imageURL: URL?,
    email: String?,
    friendIDs: [UserIdentifier]?,
    birthday: Date?,
    ageRange: UserAgeRange?,
    hometown: Location?,
    location: Location?,
    gender: String?,
    isLimited: Bool
  ) {
    self.userID = userID
    self.firstName = firstName
    self.middleName = middleName
    self.lastName = lastName
    self.name = name
    self.linkURL = linkURL
    self.refreshDate = refreshDate ?? Date()
    self.imageURL = imageURL
    self.email = email
    self.friendIDs = friendIDs
    self.birthday = birthday
    self.ageRange = ageRange
    self.hometown = hometown
    self.location = location
    self.gender = gender
    self.isLimited = isLimited

    super.init()
  }

  /**
   Indicates whether this type will automatically observe access token changes
   (via `AccessTokenDidChange` notifications).

   If observing changes, this class will issue a Graph request for public profile data when the current token's user
   identifier differs from the current profile. You can observe profile changes via `ProfileDidChange` notifications
   to handle an updated profile.

   - Note: If the current access token is cleared, the current profile instance remains available. It's also possible
   for `current` to return `nil` until the data is fetched.
   */
  @available(*, deprecated, message: "This method is deprecated and will be removed in the next major release. Use `isUpdatedWithAccessTokenChange` instead.")
  @objc(enableUpdatesOnAccessTokenChange:)
  public static func enableUpdatesOnAccessTokenChange(_ enabled: Bool) {
    isUpdatedWithAccessTokenChange = enabled
  }

  // swiftlint:enable line_length
  // swiftformat:enable blankLinesBetweenScopes

  @objc private static func observeAccessTokenChange(_ notification: Notification) {
    loadProfile(
      accessToken: notification.userInfo?[AccessTokenChangeNewKey] as? AccessToken,
      completion: nil
    )
  }
}

extension Profile: DependentAsType {
  struct TypeDependencies {
    var accessTokenProvider: _AccessTokenProviding.Type
    var dataStore: DataPersisting
    var graphRequestFactory: GraphRequestFactoryProtocol
    var notificationCenter: _NotificationPosting & NotificationDelivering
    var settings: SettingsProtocol
    var urlHoster: URLHosting
  }

  static var configuredDependencies: TypeDependencies?

  static var defaultDependencies: TypeDependencies?
}
