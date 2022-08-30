/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import Foundation

@objc(FBSDKAuthenticationTokenClaims)
public final class AuthenticationTokenClaims: NSObject {

  private enum Keys {
    static let aud = "aud"
    static let email = "email"
    static let exp = "exp"
    static let familyName = "family_name"
    static let givenName = "given_name"
    static let iat = "iat"
    static let iss = "iss"
    static let jti = "jti"
    static let middleName = "middle_name"
    static let name = "name"
    static let nonce = "nonce"
    static let picture = "picture"
    static let sub = "sub"
    static let userAgeRange = "user_age_range"
    static let userBirthday = "user_birthday"
    static let userFriends = "user_friends"
    static let userGender = "user_gender"
    static let userHometown = "user_hometown"
    static let userLink = "user_link"
    static let userLocation = "user_location"
  }

  private enum Values {
    static let validHost = "facebook.com"
    static let validHostSuffix = ".facebook.com"
  }

  /// A unique identifier for the token.
  public let jti: String

  /// Issuer Identifier for the Issuer of the response.
  public let iss: String

  /// Audience(s) that this ID Token is intended for.
  public let aud: String

  /// String value used to associate a Client session with an ID Token, and to mitigate replay attacks.
  public let nonce: String

  /// Expiration time on or after which the ID Token MUST NOT be accepted for processing.
  public let exp: TimeInterval

  /// Time at which the JWT was issued.
  public let iat: TimeInterval

  /// Subject - Identifier for the End-User at the Issuer.
  public let sub: String

  /// End-User's full name in displayable form including all name parts.
  public let name: String?

  /// End-User's given name in displayable form
  public let givenName: String?

  /// End-User's middle name in displayable form
  public let middleName: String?

  /// End-User's family name in displayable form
  public let familyName: String?

  /**
   End-User's preferred e-mail address.

   IMPORTANT: This field will only be populated if your user has granted your application the 'email' permission.
   */
  public let email: String?

  /// URL of the End-User's profile picture.
  public let picture: String?

  /**
   End-User's friends.

   IMPORTANT: This field will only be populated if your user has granted your application the 'user_friends' permission.
   */
  public let userFriends: [String]?

  /// End-User's birthday
  public let userBirthday: String?

  /// End-User's age range
  public let userAgeRange: [String: NSNumber]?

  /// End-User's hometown
  public let userHometown: [String: String]?

  /// End-User's location
  public let userLocation: [String: String]?

  /// End-User's gender
  public let userGender: String?

  /// End-User's link
  public let userLink: String?

  /**
   Internal method exposed to facilitate transition to Swift.
   API Subject to change or removal without warning. Do not use.

   @warning INTERNAL - DO NOT USE
   */
  @objc(initWithEncodedClaims:nonce:)
  public convenience init?(
    encodedClaims: String,
    nonce expectedNonce: String
  ) {
    guard let claimsData = Base64.decode(asData: Base64.base64(fromBase64Url: encodedClaims)),
          let claimsDictionary = try? JSONSerialization.jsonObject(with: claimsData) as? [String: Any]
    else {
      return nil
    }

    let currentTime = Date().timeIntervalSince1970
    let maxTimeSinceTokenIssued: TimeInterval = 10 * 60 // 10 mins

    guard let validJTI = claimsDictionary[Keys.jti] as? String,
          !validJTI.isEmpty,
          // Validate issuer
          let issuer = claimsDictionary[Keys.iss] as? String,
          let issuerURL = URL(string: issuer),
          let host = issuerURL.host,
          host == Values.validHost || host.hasSuffix(Values.validHostSuffix),
          // Validate audience
          let dependencies = try? AuthenticationTokenClaims.getDependencies(),
          let audience = claimsDictionary[Keys.aud] as? String,
          audience == dependencies.settings.appID,
          // Validate expireation
          let expiration = claimsDictionary[Keys.exp] as? Double,
          expiration > currentTime,
          // Validate 'issued at' timestamp
          let issuedTimestamp = claimsDictionary[Keys.iat] as? Double,
          issuedTimestamp >= currentTime - maxTimeSinceTokenIssued,
          // Validate nonce
          let validNonce = claimsDictionary[Keys.nonce] as? String,
          !validNonce.isEmpty,
          validNonce == expectedNonce,
          // Validate subject
          let subject = claimsDictionary[Keys.sub] as? String,
          !subject.isEmpty
    else {
      return nil
    }

    var potentialAgeRange: [String: NSNumber]?
    if let rawAgeRange = claimsDictionary[Keys.userAgeRange] as? [String: NSNumber],
       !rawAgeRange.isEmpty {
      potentialAgeRange = rawAgeRange
    }

    var potentialHometown: [String: String]?
    if let hometown = claimsDictionary[Keys.userHometown] as? [String: String],
       !hometown.isEmpty {
      potentialHometown = hometown
    }

    var potentialLocation: [String: String]?
    if let location = claimsDictionary[Keys.userLocation] as? [String: String],
       !location.isEmpty {
      potentialLocation = location
    }

    self.init(
      jti: validJTI,
      iss: issuer,
      aud: audience,
      nonce: validNonce,
      exp: expiration,
      iat: issuedTimestamp,
      sub: subject,
      name: claimsDictionary[Keys.name] as? String,
      givenName: claimsDictionary[Keys.givenName] as? String,
      middleName: claimsDictionary[Keys.middleName] as? String,
      familyName: claimsDictionary[Keys.familyName] as? String,
      email: claimsDictionary[Keys.email] as? String,
      picture: claimsDictionary[Keys.picture] as? String,
      userFriends: claimsDictionary[Keys.userFriends] as? [String],
      userBirthday: claimsDictionary[Keys.userBirthday] as? String,
      userAgeRange: potentialAgeRange,
      userHometown: potentialHometown,
      userLocation: potentialLocation,
      userGender: claimsDictionary[Keys.userGender] as? String,
      userLink: claimsDictionary[Keys.userLink] as? String
    )
  }

  init(
    jti: String,
    iss: String,
    aud: String,
    nonce: String,
    exp: TimeInterval,
    iat: TimeInterval,
    sub: String,
    name: String?,
    givenName: String?,
    middleName: String?,
    familyName: String?,
    email: String?,
    picture: String?,
    userFriends: [String]?,
    userBirthday: String?,
    userAgeRange: [String: NSNumber]?,
    userHometown: [String: String]?,
    userLocation: [String: String]?,
    userGender: String?,
    userLink: String?
  ) {
    self.jti = jti
    self.iss = iss
    self.aud = aud
    self.nonce = nonce
    self.exp = exp
    self.iat = iat
    self.sub = sub
    self.name = name
    self.givenName = givenName
    self.middleName = middleName
    self.familyName = familyName
    self.email = email
    self.picture = picture
    self.userFriends = userFriends
    self.userBirthday = userBirthday
    self.userAgeRange = userAgeRange
    self.userHometown = userHometown
    self.userLocation = userLocation
    self.userGender = userGender
    self.userLink = userLink
  }
}

extension AuthenticationTokenClaims: DependentAsType {
  struct TypeDependencies {
    var settings: SettingsProtocol
  }

  static var configuredDependencies: TypeDependencies?

  static var defaultDependencies: TypeDependencies? = TypeDependencies(
    settings: Settings.shared
  )
}
