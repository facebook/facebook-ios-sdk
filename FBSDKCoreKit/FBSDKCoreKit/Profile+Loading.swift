/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import Foundation

extension Profile {

  private static let encodedDateFormat = "MM/dd/yyyy"
  private static let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = encodedDateFormat
    return formatter
  }()

  /**
   Loads the current profile and passes it to the completion block.

   - Parameter: completion The block to be executed once the profile is loaded.

   - Note: If the profile is already loaded, this method will call the completion block synchronously, otherwise it
   will begin a graph request to update `current` and then call the completion block when finished.
   */
  @objc(loadCurrentProfileWithCompletion:)
  public static func loadCurrentProfile(completion: ProfileBlock?) {
    let dependencies: TypeDependencies
    do {
      dependencies = try getDependencies()
    } catch {
      completion?(nil, error)
      return
    }

    return loadProfile(accessToken: dependencies.accessTokenProvider.current, completion: completion)
  }

  private static var runningConnection: GraphRequestConnecting?

  private var isExpired: Bool {
    Date().timeIntervalSince(refreshDate) > Self.expirationInterval
  }

  static func loadProfile(accessToken: AccessToken?, completion: ProfileBlock?) {
    let dependencies: TypeDependencies
    do {
      dependencies = try getDependencies()
    } catch {
      completion?(nil, error)
      return
    }

    let request = dependencies.graphRequestFactory.createGraphRequest(
      withGraphPath: URLValues.path,
      parameters: makeGraphRequestParameters(token: accessToken),
      flags: [.doNotInvalidateTokenOnError, .disableErrorRecovery]
    )

    let isCurrentProfileExpired = current?.isExpired ?? false

    guard
      let token = accessToken,
      isCurrentProfileExpired || (current?.userID != token.userID) || (current?.isLimited ?? false)
    else {
      completion?(current, nil)
      return
    }

    let capturedProfile = current
    runningConnection?.cancel()

    runningConnection = request.start { _, result, error in
      guard capturedProfile === current else {
        completion?(nil, nil)
        return
      }

      guard
        let response = result,
        error == nil
      else {
        current = nil
        completion?(nil, error)
        return
      }

      let profile = parseLoadResponse(response)
      current = profile
      completion?(profile, nil)
    }
  }

  private static func parseLoadResponse(_ response: Any) -> Profile? {
    guard
      let response = response as? [String: Any],
      let identifier = response[ResponseKey.identifier.rawValue] as? String,
      !identifier.isEmpty
    else { return nil }

    let rawLinkURL = response[ResponseKey.link.rawValue] as? String
    let linkURL = (response[ResponseKey.link.rawValue] as? URL) ?? (rawLinkURL.flatMap(URL.init(string:)))

    let friendsResponse = response[ResponseKey.friends.rawValue] as? [String: Any]
    let friends = friendsResponse.flatMap(friendIdentifiers(from:))

    let ageRangeResponse = response[ResponseKey.ageRange.rawValue] as? [String: NSNumber]
    let ageRange = ageRangeResponse.flatMap(UserAgeRange.init(from:))

    let rawBirthday = response[ResponseKey.birthday.rawValue] as? String
    let birthday = rawBirthday.flatMap { dateFormatter.date(from: $0) }
    let rawHometown = response[ResponseKey.hometown.rawValue] as? [String: String]
    let hometown = rawHometown.flatMap(Location.init(from:))
    let rawLocation = response[ResponseKey.location.rawValue] as? [String: String]
    let location = rawLocation.flatMap(Location.init(from:))
    let gender = response[ResponseKey.gender.rawValue] as? String

    return Self(
      userID: identifier,
      firstName: response[ResponseKey.firstName.rawValue] as? String,
      middleName: response[ResponseKey.middleName.rawValue] as? String,
      lastName: response[ResponseKey.lastName.rawValue] as? String,
      name: response[ResponseKey.name.rawValue] as? String,
      linkURL: linkURL,
      refreshDate: Date(),
      imageURL: nil,
      email: response[ResponseKey.email.rawValue] as? String,
      friendIDs: friends,
      birthday: birthday,
      ageRange: ageRange,
      hometown: hometown,
      location: location,
      gender: gender
    )
  }

  static func makeGraphRequestParameters(token: AccessToken?) -> [String: String] {
    let fields = getGraphFields(token: token)
      .map(\.rawValue)
      .joined(separator: URLValues.fieldSeparator)

    return [URLValues.fieldsItemName: fields]
  }

  private static func getGraphFields(token: AccessToken?) -> [Field] {
    let primaryFields: [Field] = [.identifier, .firstName, .middleName, .lastName, .fullName]
    guard let token = token else { return primaryFields }

    let secondaryFieldsByPermission: [Permission: Field] = [
      .userLink: .link,
      .email: .email,
      .userFriends: .friends,
      .userBirthday: .birthday,
      .userAgeRange: .ageRange,
      .userHometown: .hometown,
      .userLocation: .location,
      .userGender: .gender,
    ]

    let secondaryFields = secondaryFieldsByPermission.compactMap { permission, field in
      token.permissions.contains(permission) ? field : nil
    }

    return primaryFields + secondaryFields
  }

  private static func friendIdentifiers(from response: [String: Any]) -> [UserIdentifier]? {
    guard let rawIdentifiers = response[ResponseKey.data.rawValue] as? [[String: Any]] else { return nil }

    let identifiers = rawIdentifiers.compactMap { $0[ResponseKey.identifier.rawValue] as? UserIdentifier }
    return identifiers.isEmpty ? nil : identifiers
  }

  private enum ResponseKey: String {
    case identifier = "id"
    case link
    case friends
    case ageRange = "age_range"
    case birthday
    case hometown
    case location
    case gender
    case firstName = "first_name"
    case middleName = "middle_name"
    case lastName = "last_name"
    case name
    case email
    case data
  }

  private enum URLValues {
    static let path = "me"
    static let fieldsItemName = "fields"
    static let fieldSeparator = ","
  }

  private enum Field: String {
    case identifier = "id"
    case firstName = "first_name"
    case middleName = "middle_name"
    case lastName = "last_name"
    case fullName = "name"
    case link
    case email
    case friends
    case birthday
    case ageRange = "age_range"
    case hometown
    case location
    case gender
  }

  private static let expirationInterval = TimeInterval(
    60 /* seconds */ * 60 /* minutes */ * 24 /* hours */
  ) /* one day in seconds */
}
