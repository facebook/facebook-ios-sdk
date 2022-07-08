/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

@testable import FBSDKLoginKit

import FBSDKCoreKit
import FBSDKCoreKit_Basics
import TestTools
import XCTest

final class LoginUtilityTests: XCTestCase {

  enum Keys {
    static let expiresIn = "expires_in"
    static let accessToken = "access_token"
    static let grantedScopes = "granted_scopes"
    static let userID = "user_id"
    static let state = "state"
    static let deniedScopes = "denied_scopes"
    static let signedRequest = "signed_request"
    static let idToken = "id_token"
    static let errorReason = "error_reason"
    static let error = "error"
    static let errorCode = "error_code"
    static let errorDescription = "error_description"
  }

  enum Values {
    static let accessToken = "sometoken"
    static let challenge = #"{"challenge":"a%20%3Dbcdef"}"#
    static let error = "access_denied"
    static let errorCode = "200"
    static let errorReason = "user_denied"
    static let expiration = "5183949"
    static let signedRequest = "ggarbage.eyJhbGdvcml0aG0iOiJITUFDSEEyNTYiLCJjb2RlIjoid2h5bm90IiwiaXNzdWVkX2F0IjoxNDIyNTAyMDkyLCJ1c2VyX2lkIjoiMTIzIn0" // swiftlint:disable:this line_length
    static let urlEncodedChallenge = "%7B%22challenge%22%3A%22a%2520%253Dbcdef%22%7D"
    static let idToken = "eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCIsImtpZCI6ImFiY2QxMjM0In0=.eyJ1c2VyX2xvY2F0aW9uIjp7ImlkIjoiMTEwODQzNDE4OTQwNDg0IiwibmFtZSI6IlNlYXR0bGUsIFdhc2hpbmd0b24ifSwidXNlcl9saW5rIjoiaHR0cHM6XC9cL3d3dy5mYWNlYm9vay5jb20iLCJzdWIiOiIxMjM0IiwiaWF0IjoxNjM3NjkxOTUwLCJqdGkiOiJhIGp0aSBpcyBqdXN0IGFueSBzdHJpbmciLCJwaWN0dXJlIjoiaHR0cHM6XC9cL3d3dy5mYWNlYm9vay5jb21cL3NvbWVfcGljdHVyZSIsInVzZXJfYWdlX3JhbmdlIjp7Im1pbiI6MjF9LCJ1c2VyX2ZyaWVuZHMiOlsiMTIzIiwiNDU2Il0sImlzcyI6Imh0dHBzOlwvXC9mYWNlYm9vay5jb21cL2RpYWxvZ1wvb2F1dGgiLCJtaWRkbGVfbmFtZSI6Ik1pZGRsZSIsImF1ZCI6IjczOTE2Mjg0MzkiLCJmYW1pbHlfbmFtZSI6IlVzZXIiLCJuYW1lIjoiVGVzdCBVc2VyIiwidXNlcl9iaXJ0aGRheSI6IjAxXC8wMVwvMTk5MCIsIm5vbmNlIjoiZmVkY2IgPWEiLCJleHAiOjE2Mzc4NjQ4MTAsImdpdmVuX25hbWUiOiJUZXN0IiwidXNlcl9nZW5kZXIiOiJtYWxlIiwiZW1haWwiOiJlbWFpbEBlbWFpbC5jb20iLCJ1c2VyX2hvbWV0b3duIjp7ImlkIjoiMTEyNzI0OTYyMDc1OTk2IiwibmFtZSI6Ik1hcnR" // swiftlint:disable:this line_length
    static let invalidToken = "invalid_token"
    static let userID = "123"
    static let publicProfile = "public_profile"
  }

  func testQueryParamsFromLoginURLWithGrantedAndDeniedScopes() throws {
    let url = try XCTUnwrap(
      URL(string: "fb7391628439://authorize/#granted_scopes=public_profile&denied_scopes=email%2Cuser_friends&signed_request=ggarbage.eyJhbGdvcml0aG0iOiJITUFDSEEyNTYiLCJjb2RlIjoid2h5bm90IiwiaXNzdWVkX2F0IjoxNDIyNTAyMDkyLCJ1c2VyX2lkIjoiMTIzIn0&access_token=sometoken&expires_in=5183949&state=%7B%22challenge%22%3A%22a%2520%253Dbcdef%22%7D")
    )
    let parameters = try XCTUnwrap(LoginUtility.getQueryParameters(from: url) as? [String: String])

    XCTAssertEqual(parameters[Keys.expiresIn], Values.expiration)
    XCTAssertEqual(parameters[Keys.accessToken], Values.accessToken)
    XCTAssertEqual(parameters[Keys.grantedScopes], Values.publicProfile)
    XCTAssertEqual(parameters[Keys.userID], Values.userID)
    XCTAssertEqual(parameters[Keys.state], Values.challenge)
    XCTAssertEqual(parameters[Keys.deniedScopes], "email,user_friends")
    XCTAssertEqual(parameters[Keys.signedRequest], Values.signedRequest)

    XCTAssertNil(parameters[Keys.idToken])
    XCTAssertNil(parameters[Keys.errorReason])
    XCTAssertNil(parameters[Keys.error])
    XCTAssertNil(parameters[Keys.errorCode])
    XCTAssertNil(parameters[Keys.errorDescription])
  }

  func testQueryParamsFromLoginURLWithError() throws {
    let url = try XCTUnwrap(
      URL(string: "fb7391628439://authorize/?error=access_denied&error_code=200&error_description=Permissions+error&error_reason=user_denied#_=_")
    )
    let parameters = try XCTUnwrap(LoginUtility.getQueryParameters(from: url) as? [String: String])

    XCTAssertNil(parameters[Keys.expiresIn])
    XCTAssertNil(parameters[Keys.accessToken])
    XCTAssertNil(parameters[Keys.grantedScopes])
    XCTAssertNil(parameters[Keys.userID])
    XCTAssertNil(parameters[Keys.state])
    XCTAssertNil(parameters[Keys.deniedScopes])
    XCTAssertNil(parameters[Keys.signedRequest])
    XCTAssertNil(parameters[Keys.idToken])

    XCTAssertEqual(parameters[Keys.errorReason], Values.errorReason)
    XCTAssertEqual(parameters[Keys.error], Values.error)
    XCTAssertEqual(parameters[Keys.errorCode], Values.errorCode)
    XCTAssertEqual(parameters[Keys.errorDescription], "Permissions error")
  }

  func testQueryParamsFromLoginURLWithGrantedScopesWithoutDeniedScopes() throws {
    let url = try XCTUnwrap(
      URL(string: "fb7391628439://authorize/#granted_scopes=public_profile&denied_scopes=&signed_request=ggarbage.eyJhbGdvcml0aG0iOiJITUFDSEEyNTYiLCJjb2RlIjoid2h5bm90IiwiaXNzdWVkX2F0IjoxNDIyNTAyMDkyLCJ1c2VyX2lkIjoiMTIzIn0&access_token=sometoken&expires_in=5183949&state=%7B%22challenge%22%3A%22a%2520%253Dbcdef%22%7D")
    )
    let parameters = try XCTUnwrap(LoginUtility.getQueryParameters(from: url) as? [String: String])

    XCTAssertEqual(parameters[Keys.expiresIn], Values.expiration)
    XCTAssertEqual(parameters[Keys.accessToken], Values.accessToken)
    XCTAssertEqual(parameters[Keys.grantedScopes], Values.publicProfile)
    XCTAssertEqual(parameters[Keys.userID], Values.userID)
    XCTAssertEqual(parameters[Keys.state], Values.challenge)
    XCTAssertEqual(parameters[Keys.deniedScopes], "")
    XCTAssertEqual(parameters[Keys.signedRequest], Values.signedRequest)

    XCTAssertNil(parameters[Keys.idToken])
    XCTAssertNil(parameters[Keys.errorReason])
    XCTAssertNil(parameters[Keys.error])
    XCTAssertNil(parameters[Keys.errorCode])
    XCTAssertNil(parameters[Keys.errorDescription])
  }

  func testQueryParamsFromLoginURLWithGrantedScopesWithIDToken() throws {
    let url = try XCTUnwrap(
      URL(string: "fb7391628439://authorize/#granted_scopes=public_profile,email,user_friends,user_birthday,user_age_range,user_hometown,user_location,user_gender,user_link&id_token=eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCIsImtpZCI6ImFiY2QxMjM0In0=.eyJ1c2VyX2xvY2F0aW9uIjp7ImlkIjoiMTEwODQzNDE4OTQwNDg0IiwibmFtZSI6IlNlYXR0bGUsIFdhc2hpbmd0b24ifSwidXNlcl9saW5rIjoiaHR0cHM6XC9cL3d3dy5mYWNlYm9vay5jb20iLCJzdWIiOiIxMjM0IiwiaWF0IjoxNjM3NjkxOTUwLCJqdGkiOiJhIGp0aSBpcyBqdXN0IGFueSBzdHJpbmciLCJwaWN0dXJlIjoiaHR0cHM6XC9cL3d3dy5mYWNlYm9vay5jb21cL3NvbWVfcGljdHVyZSIsInVzZXJfYWdlX3JhbmdlIjp7Im1pbiI6MjF9LCJ1c2VyX2ZyaWVuZHMiOlsiMTIzIiwiNDU2Il0sImlzcyI6Imh0dHBzOlwvXC9mYWNlYm9vay5jb21cL2RpYWxvZ1wvb2F1dGgiLCJtaWRkbGVfbmFtZSI6Ik1pZGRsZSIsImF1ZCI6IjczOTE2Mjg0MzkiLCJmYW1pbHlfbmFtZSI6IlVzZXIiLCJuYW1lIjoiVGVzdCBVc2VyIiwidXNlcl9iaXJ0aGRheSI6IjAxXC8wMVwvMTk5MCIsIm5vbmNlIjoiZmVkY2IgPWEiLCJleHAiOjE2Mzc4NjQ4MTAsImdpdmVuX25hbWUiOiJUZXN0IiwidXNlcl9nZW5kZXIiOiJtYWxlIiwiZW1haWwiOiJlbWFpbEBlbWFpbC5jb20iLCJ1c2VyX2hvbWV0b3duIjp7ImlkIjoiMTEyNzI0OTYyMDc1OTk2IiwibmFtZSI6Ik1hcnR") // swiftlint:disable:this line_length
    )
    let parameters = try XCTUnwrap(LoginUtility.getQueryParameters(from: url) as? [String: String])

    XCTAssertEqual(
      parameters[Keys.grantedScopes],
      "public_profile,email,user_friends,user_birthday,user_age_range,user_hometown,user_location,user_gender,user_link"
    )
    XCTAssertEqual(parameters[Keys.idToken], Values.idToken)

    XCTAssertNil(parameters[Keys.expiresIn])
    XCTAssertNil(parameters[Keys.accessToken])
    XCTAssertNil(parameters[Keys.userID])
    XCTAssertNil(parameters[Keys.state])
    XCTAssertNil(parameters[Keys.deniedScopes])
    XCTAssertNil(parameters[Keys.signedRequest])
    XCTAssertNil(parameters[Keys.errorReason])
    XCTAssertNil(parameters[Keys.error])
    XCTAssertNil(parameters[Keys.errorCode])
    XCTAssertNil(parameters[Keys.errorDescription])
  }

  func testQueryParamsFromLoginURLWithGrantedScopesWithIDTokenWithAccessToken() throws {
    let url = try XCTUnwrap(
      URL(string: "fb7391628439://authorize/#granted_scopes=public_profile%2Cemail%2Cuser_friends&signed_request=ggarbage.eyJhbGdvcml0aG0iOiJITUFDSEEyNTYiLCJjb2RlIjoid2h5bm90IiwiaXNzdWVkX2F0IjoxNDIyNTAyMDkyLCJ1c2VyX2lkIjoiMTIzIn0&access_token=sometoken&expires_in=5183949&id_token=eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCIsImtpZCI6ImFiY2QxMjM0In0=.eyJ1c2VyX2xvY2F0aW9uIjp7ImlkIjoiMTEwODQzNDE4OTQwNDg0IiwibmFtZSI6IlNlYXR0bGUsIFdhc2hpbmd0b24ifSwidXNlcl9saW5rIjoiaHR0cHM6XC9cL3d3dy5mYWNlYm9vay5jb20iLCJzdWIiOiIxMjM0IiwiaWF0IjoxNjM3NjkxOTUwLCJqdGkiOiJhIGp0aSBpcyBqdXN0IGFueSBzdHJpbmciLCJwaWN0dXJlIjoiaHR0cHM6XC9cL3d3dy5mYWNlYm9vay5jb21cL3NvbWVfcGljdHVyZSIsInVzZXJfYWdlX3JhbmdlIjp7Im1pbiI6MjF9LCJ1c2VyX2ZyaWVuZHMiOlsiMTIzIiwiNDU2Il0sImlzcyI6Imh0dHBzOlwvXC9mYWNlYm9vay5jb21cL2RpYWxvZ1wvb2F1dGgiLCJtaWRkbGVfbmFtZSI6Ik1pZGRsZSIsImF1ZCI6IjczOTE2Mjg0MzkiLCJmYW1pbHlfbmFtZSI6IlVzZXIiLCJuYW1lIjoiVGVzdCBVc2VyIiwidXNlcl9iaXJ0aGRheSI6IjAxXC8wMVwvMTk5MCIsIm5vbmNlIjoiZmVkY2IgPWEiLCJleHAiOjE2Mzc4NjQ4MTAsImdpdmVuX25hbWUiOiJUZXN0IiwidXNlcl9nZW5kZXIiOiJtYWxlIiwiZW1haWwiOiJlbWFpbEBlbWFpbC5jb20iLCJ1c2VyX2hvbWV0b3duIjp7ImlkIjoiMTEyNzI0OTYyMDc1OTk2IiwibmFtZSI6Ik1hcnR") // swiftlint:disable:this line_length
    )
    let parameters = try XCTUnwrap(LoginUtility.getQueryParameters(from: url) as? [String: String])

    XCTAssertEqual(parameters[Keys.idToken], Values.idToken)
    XCTAssertEqual(parameters[Keys.expiresIn], Values.expiration)
    XCTAssertEqual(parameters[Keys.accessToken], Values.accessToken)
    XCTAssertEqual(parameters[Keys.grantedScopes], "public_profile,email,user_friends")
    XCTAssertEqual(parameters[Keys.userID], Values.userID)
    XCTAssertEqual(parameters[Keys.signedRequest], Values.signedRequest)

    XCTAssertNil(parameters[Keys.state])
    XCTAssertNil(parameters[Keys.deniedScopes])
    XCTAssertNil(parameters[Keys.errorReason])
    XCTAssertNil(parameters[Keys.error])
    XCTAssertNil(parameters[Keys.errorCode])
    XCTAssertNil(parameters[Keys.errorDescription])
  }

  func testQueryParamsFromLoginURLWithInvalidToken() throws {
    let url = try XCTUnwrap(
      URL(string: "fb7391628439://authorize/#id_token=invalid_token&state=%7B%22challenge%22%3A%22a%2520%253Dbcdef%22%7D")
    )
    let parameters = try XCTUnwrap(LoginUtility.getQueryParameters(from: url) as? [String: String])

    XCTAssertEqual(parameters[Keys.state], Values.challenge)
    XCTAssertEqual(parameters[Keys.idToken], Values.invalidToken)

    XCTAssertNil(parameters[Keys.expiresIn])
    XCTAssertNil(parameters[Keys.accessToken])
    XCTAssertNil(parameters[Keys.grantedScopes])
    XCTAssertNil(parameters[Keys.userID])
    XCTAssertNil(parameters[Keys.deniedScopes])
    XCTAssertNil(parameters[Keys.signedRequest])
    XCTAssertNil(parameters[Keys.errorReason])
    XCTAssertNil(parameters[Keys.error])
    XCTAssertNil(parameters[Keys.errorCode])
    XCTAssertNil(parameters[Keys.errorDescription])
  }

  func testQueryParamsFromLoginURLWithDeniedScopesWithoutGrantedScopes() throws {
    let url = try XCTUnwrap(
      URL(string: "fb7391628439://authorize/#denied_scopes=user_friends,user_likes&signed_request=ggarbage.eyJhbGdvcml0aG0iOiJITUFDSEEyNTYiLCJjb2RlIjoid2h5bm90IiwiaXNzdWVkX2F0IjoxNDIyNTAyMDkyLCJ1c2VyX2lkIjoiMTIzIn0&access_token=sometoken&expires_in=5183949&state=%7B%22challenge%22%3A%22a%2520%253Dbcdef%22%7D")
    )
    let parameters = try XCTUnwrap(LoginUtility.getQueryParameters(from: url) as? [String: String])

    XCTAssertEqual(parameters[Keys.state], Values.challenge)

    XCTAssertEqual(parameters[Keys.expiresIn], Values.expiration)
    XCTAssertEqual(parameters[Keys.accessToken], Values.accessToken)
    XCTAssertEqual(parameters[Keys.signedRequest], Values.signedRequest)
    XCTAssertEqual(parameters[Keys.userID], Values.userID)
    XCTAssertEqual(parameters[Keys.deniedScopes], "user_friends,user_likes")

    XCTAssertNil(parameters[Keys.grantedScopes])
    XCTAssertNil(parameters[Keys.idToken])
    XCTAssertNil(parameters[Keys.errorReason])
    XCTAssertNil(parameters[Keys.error])
    XCTAssertNil(parameters[Keys.errorCode])
    XCTAssertNil(parameters[Keys.errorDescription])
  }

  func testQueryParamsFromLoginURLWithoutFacebookDomainWithoutAuthorizeHost() throws {
    let url = try XCTUnwrap(
      URL(string: "test://test?granted_scopes=public_profile&access_token=sometoken&expires_in=5183949")
    )
    XCTAssertNil(LoginUtility.getQueryParameters(from: url))
  }

  func testQueryParamsFromLoginURLWithoutFacebookDomainWithAuthorizeHost() throws {
    let url = try XCTUnwrap(
      URL(string: "test://authorize?granted_scopes=public_profile&access_token=sometoken&expires_in=5183949")
    )
    let parameters = try XCTUnwrap(LoginUtility.getQueryParameters(from: url) as? [String: String])

    XCTAssertNil(parameters[Keys.state])

    XCTAssertEqual(parameters[Keys.expiresIn], Values.expiration)
    XCTAssertEqual(parameters[Keys.accessToken], Values.accessToken)
    XCTAssertEqual(parameters[Keys.grantedScopes], Values.publicProfile)

    XCTAssertNil(parameters[Keys.signedRequest])
    XCTAssertNil(parameters[Keys.userID])
    XCTAssertNil(parameters[Keys.deniedScopes])
    XCTAssertNil(parameters[Keys.idToken])
    XCTAssertNil(parameters[Keys.errorReason])
    XCTAssertNil(parameters[Keys.error])
    XCTAssertNil(parameters[Keys.errorCode])
    XCTAssertNil(parameters[Keys.errorDescription])
  }

  func testStringForAudienceOnlyMe() {
    let audienceString = LoginUtility.stringForAudience(.onlyMe)
    XCTAssertEqual(audienceString, "only_me", .providesStringForAudience)
  }

  func testStringForAudienceFriends() {
    let audienceString = LoginUtility.stringForAudience(.friends)
    XCTAssertEqual(audienceString, "friends", .providesStringForAudience)
  }

  func testStringForAudienceEveryone() {
    let audienceString = LoginUtility.stringForAudience(.everyone)
    XCTAssertEqual(audienceString, "everyone", .providesStringForAudience)
  }
}

// MARK: - Assumptions

fileprivate extension String {
  static let providesStringForAudience = "Utility provides strings for default audience values"
}
