/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import Foundation

extension Profile: ProfileProviding {
  /// The current profile.
  @objc(currentProfile)
  public static var current: Profile? {
    get { _current }
    set {
      guard
        newValue != nil || _current != nil,
        newValue !== _current
      else { return }

      if let old = _current,
         let new = newValue,
         new.hasEqualProperties(to: old) {
        return
      } else {
        let old = _current
        _current = newValue
        Self.cacheProfile(newValue)
        postChangeNotification(old: old, new: newValue)
      }
    }
  }

  private func hasEqualProperties(to other: Profile) -> Bool {
    userID == other.userID
      && firstName == other.firstName
      && middleName == other.middleName
      && lastName == other.lastName
      && name == other.name
      && linkURL == other.linkURL
      && refreshDate == other.refreshDate
      && imageURL == other.imageURL
      && email == other.email
      && friendIDs == other.friendIDs
      && isLimited == other.isLimited
      && birthday == other.birthday
      && ageRange == other.ageRange
      && hometown == other.hometown
      && location == other.location
      && gender == other.gender
  }

  public static func fetchCachedProfile() -> Self? {
    guard let data = Self.dataStore?.fb_object(forKey: profileUserDefaultsKey) as? Data else {
      return nil
    }

    let unarchiver = UnarchiverProvider.createSecureUnarchiver(for: data)
    return unarchiver.decodeObject(of: Profile.self, forKey: NSKeyedArchiveRootObjectKey) as? Self
  }

  private static func cacheProfile(_ profile: Profile?) {
    guard
      let profile = profile,
      let data = try? NSKeyedArchiver.archivedData(withRootObject: profile, requiringSecureCoding: false)
    else {
      // swiftformat:disable:next redundantSelf
      self.dataStore?.fb_removeObject(forKey: profileUserDefaultsKey)
      return
    }

    // swiftformat:disable:next redundantSelf
    self.dataStore?.fb_setObject(data, forKey: profileUserDefaultsKey)
  }

  private static func postChangeNotification(old: Profile?, new: Profile?) {
    Self.notificationCenter?.fb_post(
      name: .ProfileDidChange,
      object: Self.self,
      userInfo: [
        ProfileChangeNewKey: new,
        ProfileChangeOldKey: old,
      ].compactMapValues { $0 }
    )
  }
}

extension Profile: NSSecureCoding {
  static let profileUserDefaultsKey = "com.facebook.sdk.FBSDKProfile.currentProfile"

  public static var supportsSecureCoding: Bool { true }

  public convenience init?(coder decoder: NSCoder) {
    guard let identifier = decoder.decodeObject(
      of: NSString.self,
      forKey: CodingKeys.userID.rawValue
    ) as? UserIdentifier
    else { return nil }

    let firstName = decoder.decodeObject(of: NSString.self, forKey: CodingKeys.firstName.rawValue)
    let middleName = decoder.decodeObject(of: NSString.self, forKey: CodingKeys.middleName.rawValue)
    let lastName = decoder.decodeObject(of: NSString.self, forKey: CodingKeys.lastName.rawValue)
    let name = decoder.decodeObject(of: NSString.self, forKey: CodingKeys.name.rawValue)
    let linkURL = decoder.decodeObject(of: NSURL.self, forKey: CodingKeys.linkURL.rawValue)
    let refreshDate = decoder.decodeObject(of: NSDate.self, forKey: CodingKeys.refreshDate.rawValue)
    let imageURL = decoder.decodeObject(of: NSURL.self, forKey: CodingKeys.imageURL.rawValue)
    let email = decoder.decodeObject(of: NSString.self, forKey: CodingKeys.email.rawValue)
    let friendIDs = decoder.decodeObject(
      of: [NSArray.self, NSString.self],
      forKey: CodingKeys.friendIDs.rawValue
    ) as? [UserIdentifier]
    let isLimited = decoder.decodeBool(forKey: CodingKeys.isLimited.rawValue)
    let birthday = decoder.decodeObject(of: NSDate.self, forKey: CodingKeys.birthday.rawValue)
    let ageRange = decoder.decodeObject(of: UserAgeRange.self, forKey: CodingKeys.ageRange.rawValue)
    let hometown = decoder.decodeObject(of: Location.self, forKey: CodingKeys.hometown.rawValue)
    let location = decoder.decodeObject(of: Location.self, forKey: CodingKeys.location.rawValue)
    let gender = decoder.decodeObject(of: NSString.self, forKey: CodingKeys.gender.rawValue)

    self.init(
      userID: identifier,
      firstName: firstName as String?,
      middleName: middleName as String?,
      lastName: lastName as String?,
      name: name as String?,
      linkURL: linkURL as URL?,
      refreshDate: refreshDate as Date?,
      imageURL: imageURL as URL?,
      email: email as String?,
      friendIDs: friendIDs,
      birthday: birthday as Date?,
      ageRange: ageRange,
      hometown: hometown,
      location: location,
      gender: gender as String?,
      isLimited: isLimited
    )
  }

  public func encode(with encoder: NSCoder) {
    encoder.encode(userID, forKey: CodingKeys.userID.rawValue)
    encoder.encode(firstName, forKey: CodingKeys.firstName.rawValue)
    encoder.encode(middleName, forKey: CodingKeys.middleName.rawValue)
    encoder.encode(lastName, forKey: CodingKeys.lastName.rawValue)
    encoder.encode(name, forKey: CodingKeys.name.rawValue)
    encoder.encode(linkURL, forKey: CodingKeys.linkURL.rawValue)
    encoder.encode(refreshDate, forKey: CodingKeys.refreshDate.rawValue)
    encoder.encode(imageURL, forKey: CodingKeys.imageURL.rawValue)
    encoder.encode(email, forKey: CodingKeys.email.rawValue)
    encoder.encode(friendIDs, forKey: CodingKeys.friendIDs.rawValue)
    encoder.encode(isLimited, forKey: CodingKeys.isLimited.rawValue)
    encoder.encode(birthday, forKey: CodingKeys.birthday.rawValue)
    encoder.encode(ageRange, forKey: CodingKeys.ageRange.rawValue)
    encoder.encode(hometown, forKey: CodingKeys.hometown.rawValue)
    encoder.encode(location, forKey: CodingKeys.location.rawValue)
    encoder.encode(gender, forKey: CodingKeys.gender.rawValue)
  }

  enum CodingKeys: String, CodingKey {
    case userID
    case firstName
    case middleName
    case lastName
    case name
    case linkURL
    case refreshDate
    case imageURL
    case email
    case friendIDs
    case isLimited
    case birthday
    case ageRange
    case hometown
    case location
    case gender
  }
}
