// Copyright (c) 2014-present, Facebook, Inc. All rights reserved.
//
// You are hereby granted a non-exclusive, worldwide, royalty-free license to use,
// copy, modify, and distribute this software in source code or binary form for use
// in connection with the web services and APIs provided by Facebook.
//
// As with any software that integrates with the Facebook platform, your use of
// this software is subject to the Facebook Developer Principles and Policies
// [http://developers.facebook.com/policy/]. This copyright notice shall be
// included in all copies or substantial portions of the software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
// FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
// COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
// IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
// CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

import FBSDKCoreKit
import TestTools
import XCTest

class ProfileTests: XCTestCase { // swiftlint:disable:this type_body_length
  var store = UserDefaultsSpy()
  var notificationCenter = TestNotificationCenter()
  let settings = TestSettings()
  let stubbedURL = URL(string: "testProfile.com")! // swiftlint:disable:this force_unwrapping
  lazy var urlHoster = TestURLHoster(url: stubbedURL)

  let accessTokenKey = "access_token"
  let pictureModeKey = "type"
  let widthKey = "width"
  let heightKey = "height"
  let sdkVersion = "100"
  let profile = SampleUserProfiles.valid
  let validClientToken = "Foo"
  let testGraphRequest = TestGraphRequest()
  var imageURL: URL! // swiftlint:disable:this implicitly_unwrapped_optional

  static let validSquareSize = CGSize(width: 100, height: 100)
  static let validNonSquareSize = CGSize(width: 10, height: 20)

  override func setUp() {
    super.setUp()

    Settings.shared.graphAPIVersion = sdkVersion
    TestAccessTokenWallet.reset()
    Profile.configure(
      store: store,
      accessTokenProvider: TestAccessTokenWallet.self,
      notificationCenter: notificationCenter,
      settings: settings,
      urlHoster: urlHoster
    )
  }

  override func tearDown() {
    super.tearDown()

    Profile.reset()
    TestAccessTokenWallet.reset()
    Profile.resetCurrentProfileCache()
  }

  private func makeImageURL(
    mode: Profile.PictureMode = .normal,
    size: CGSize = ProfileTests.validSquareSize
  ) throws {
    imageURL = try XCTUnwrap(
      profile.imageURL(
        forMode: mode,
        size: size
      )
    )
  }

  func testCreatingImageURL() throws {
    try makeImageURL()
    XCTAssertEqual(urlHoster.capturedHostPrefix, "graph")
    XCTAssertEqual(urlHoster.capturedPath, "\(profile.userID)/picture")
    XCTAssertNotNil(urlHoster.capturedQueryParameters)
    XCTAssertEqual(imageURL, urlHoster.stubbedURL)
  }

  // MARK: - Creating Image URL

  func testCreatingImageURLWithNoAccessTokenNoClientToken() throws {
    try makeImageURL()
    let queryItems = try XCTUnwrap(urlHoster.capturedQueryParameters)
    XCTAssertEqual(
      queryItems[pictureModeKey] as? String,
      "normal",
      "Should add the expected query items to a url when creating a url for fetching a profile image"
    )
    XCTAssertEqual(
      queryItems[widthKey] as? Int,
      100,
      "Should add the expected query items to a url when creating a url for fetching a profile image"
    )
    XCTAssertEqual(
      queryItems[heightKey] as? Int,
      100,
      "Should add the expected query items to a url when creating a url for fetching a profile image"
    )
  }

  func testCreatingImageURLWithClientTokenNoAccessToken() throws {
    settings.clientToken = validClientToken
    try makeImageURL()

    let queryItems = try XCTUnwrap(urlHoster.capturedQueryParameters)
    XCTAssertEqual(
      queryItems[pictureModeKey] as? String,
      "normal",
      "Should add the expected query items to a url when creating a url for fetching a profile image"
    )
    XCTAssertEqual(
      queryItems[widthKey] as? Int,
      100,
      "Should add the expected query items to a url when creating a url for fetching a profile image"
    )
    XCTAssertEqual(
      queryItems[heightKey] as? Int,
      100,
      "Should add the expected query items to a url when creating a url for fetching a profile image"
    )
    XCTAssertEqual(
      queryItems[accessTokenKey] as? String,
      "Foo",
      "Should add the expected query items to a url when creating a url for fetching a profile image"
    )
  }

  func testCreatingImageURLWithAccessTokenNoClientToken() throws {
    TestAccessTokenWallet.currentAccessToken = SampleAccessTokens.validToken
    try makeImageURL()

    let queryItems = try XCTUnwrap(urlHoster.capturedQueryParameters)
    XCTAssertEqual(
      queryItems[pictureModeKey] as? String,
      "normal",
      "Should add the expected query items to a url when creating a url for fetching a profile image"
    )
    XCTAssertEqual(
      queryItems[widthKey] as? Int,
      100,
      "Should add the expected query items to a url when creating a url for fetching a profile image"
    )
    XCTAssertEqual(
      queryItems[heightKey] as? Int,
      100,
      "Should add the expected query items to a url when creating a url for fetching a profile image"
    )
    XCTAssertEqual(
      queryItems[accessTokenKey] as? String,
      SampleAccessTokens.validToken.tokenString,
      "Should add the expected query items to a url when creating a url for fetching a profile image"
    )
  }

  func testCreatingImageURLWithAccessTokenAndClientToken() throws {
    TestAccessTokenWallet.currentAccessToken = SampleAccessTokens.validToken
    settings.clientToken = validClientToken
    try makeImageURL()

    let queryItems = try XCTUnwrap(urlHoster.capturedQueryParameters)
    XCTAssertEqual(
      queryItems[pictureModeKey] as? String,
      "normal",
      "Should add the expected query items to a url when creating a url for fetching a profile image"
    )
    XCTAssertEqual(
      queryItems[widthKey] as? Int,
      100,
      "Should add the expected query items to a url when creating a url for fetching a profile image"
    )
    XCTAssertEqual(
      queryItems[heightKey] as? Int,
      100,
      "Should add the expected query items to a url when creating a url for fetching a profile image"
    )
    XCTAssertEqual(
      queryItems[accessTokenKey] as? String,
      SampleAccessTokens.validToken.tokenString,
      "Should add the expected query items to a url when creating a url for fetching a profile image"
    )
  }

  func testCreatingEnumWithSmallMode() throws {
    try makeImageURL(mode: .small, size: ProfileTests.validNonSquareSize)

    let queryItems = try XCTUnwrap(urlHoster.capturedQueryParameters)
    XCTAssertEqual(
      queryItems[pictureModeKey] as? String,
      "small",
      "Should add the expected query items to a url when creating a url for fetching a profile image"
    )
    XCTAssertEqual(
      queryItems[widthKey] as? Int,
      10,
      "Should add the expected query items to a url when creating a url for fetching a profile image"
    )
    XCTAssertEqual(
      queryItems[heightKey] as? Int,
      20,
      "Should add the expected query items to a url when creating a url for fetching a profile image"
    )
  }

  func testCreatingEnumWithAlbumMode() throws {
    try makeImageURL(mode: .album, size: ProfileTests.validNonSquareSize)

    let queryItems = try XCTUnwrap(urlHoster.capturedQueryParameters)
    XCTAssertEqual(
      queryItems[pictureModeKey] as? String,
      "album",
      "Should add the expected query items to a url when creating a url for fetching a profile image"
    )
    XCTAssertEqual(
      queryItems[widthKey] as? Int,
      10,
      "Should add the expected query items to a url when creating a url for fetching a profile image"
    )
    XCTAssertEqual(
      queryItems[heightKey] as? Int,
      20,
      "Should add the expected query items to a url when creating a url for fetching a profile image"
    )
  }

  func testCreatingEnumWithLargeMode() throws {
    try makeImageURL(mode: .large, size: ProfileTests.validNonSquareSize)

    let queryItems = try XCTUnwrap(urlHoster.capturedQueryParameters)
    XCTAssertEqual(
      queryItems[pictureModeKey] as? String,
      "large",
      "Should add the expected query items to a url when creating a url for fetching a profile image"
    )
    XCTAssertEqual(
      queryItems[widthKey] as? Int,
      10,
      "Should add the expected query items to a url when creating a url for fetching a profile image"
    )
    XCTAssertEqual(
      queryItems[heightKey] as? Int,
      20,
      "Should add the expected query items to a url when creating a url for fetching a profile image"
    )
  }

  func testCreatingEnumWithSquareMode() throws {
    try makeImageURL(mode: .square, size: ProfileTests.validNonSquareSize)

    let queryItems = try XCTUnwrap(urlHoster.capturedQueryParameters)
    XCTAssertEqual(
      queryItems[pictureModeKey] as? String,
      "square",
      "Should add the expected query items to a url when creating a url for fetching a profile image"
    )
    XCTAssertEqual(
      queryItems[widthKey] as? Int,
      10,
      "Should add the expected query items to a url when creating a url for fetching a profile image"
    )
    XCTAssertEqual(
      queryItems[heightKey] as? Int,
      20,
      "Should add the expected query items to a url when creating a url for fetching a profile image"
    )
  }

  // MARK: - Size Validations

  func testCreatingImageURLWithNoSize() throws {
    try makeImageURL(mode: .square, size: .zero)

    let queryItems = try XCTUnwrap(urlHoster.capturedQueryParameters)
    XCTAssertEqual(
      queryItems[pictureModeKey] as? String,
      "square",
      "Should add the expected query items to a url when creating a url for fetching a profile image"
    )
    XCTAssertEqual(
      queryItems[widthKey] as? Int,
      0,
      "Should add the expected query items to a url when creating a url for fetching a profile image"
    )
    XCTAssertEqual(
      queryItems[heightKey] as? Int,
      0,
      "Should add the expected query items to a url when creating a url for fetching a profile image"
    )
  }

  func testCreatingSquareImageURLWithNonSquareSize() throws {
    try makeImageURL(mode: .square, size: ProfileTests.validNonSquareSize)

    let queryItems = try XCTUnwrap(urlHoster.capturedQueryParameters)
    XCTAssertEqual(
      queryItems[pictureModeKey] as? String,
      "square",
      "Should add the expected query items to a url when creating a url for fetching a profile image"
    )
    XCTAssertEqual(
      queryItems[widthKey] as? Int,
      10,
      "Should add the expected query items to a url when creating a url for fetching a profile image"
    )
    XCTAssertEqual(
      queryItems[heightKey] as? Int,
      20,
      "Should add the expected query items to a url when creating a url for fetching a profile image"
    )
  }

  func testCreatingSquareImageURLWithNegativeSize() throws {
    try makeImageURL(mode: .square, size: CGSize(width: -10, height: -10))

    let queryItems = try XCTUnwrap(urlHoster.capturedQueryParameters)
    XCTAssertEqual(
      queryItems[pictureModeKey] as? String,
      "square",
      "Should add the expected query items to a url when creating a url for fetching a profile image"
    )
    XCTAssertEqual(
      queryItems[widthKey] as? Int,
      -10,
      "Should add the expected query items to a url when creating a url for fetching a profile image"
    )
    XCTAssertEqual(
      queryItems[heightKey] as? Int,
      -10,
      "Should add the expected query items to a url when creating a url for fetching a profile image"
    )
  }

  // MARK: - Profile Loading

  func testGraphPathForProfileLoadWithLinkPermission() {
    verfiyGraphPath(
      expectedPath: "me?fields=id,first_name,middle_name,last_name,name,link",
      permissions: ["user_link"]
    )
  }

  func testGraphPathForProfileLoadWithNoPermission() {
    verfiyGraphPath(
      expectedPath: "me?fields=id,first_name,middle_name,last_name,name",
      permissions: []
    )
  }

  func testGraphPathForProfileLoadWithEmailPermission() {
    verfiyGraphPath(
      expectedPath: "me?fields=id,first_name,middle_name,last_name,name,email",
      permissions: ["email"]
    )
  }

  func testGraphPathForProfileLoadWithFriendsPermission() {
    verfiyGraphPath(
      expectedPath: "me?fields=id,first_name,middle_name,last_name,name,friends",
      permissions: ["user_friends"]
    )
  }

  func testGraphPathForProfileLoadWithBirthdayPermission() {
    verfiyGraphPath(
      expectedPath: "me?fields=id,first_name,middle_name,last_name,name,birthday",
      permissions: ["user_birthday"]
    )
  }

  func testGraphPathForProfileLoadWithAgeRangePermission() {
    verfiyGraphPath(
      expectedPath: "me?fields=id,first_name,middle_name,last_name,name,age_range",
      permissions: ["user_age_range"]
    )
  }

  func testGraphPathForProfileLoadWithHometownPermission() {
    verfiyGraphPath(
      expectedPath: "me?fields=id,first_name,middle_name,last_name,name,hometown",
      permissions: ["user_hometown"]
    )
  }

  func testGraphPathForProfileLoadWithLocationPermission() {
    verfiyGraphPath(
      expectedPath: "me?fields=id,first_name,middle_name,last_name,name,location",
      permissions: ["user_location"]
    )
  }

  func testGraphPathForProfileLoadWithGenderPermission() {
    verfiyGraphPath(
      expectedPath: "me?fields=id,first_name,middle_name,last_name,name,gender",
      permissions: ["user_gender"]
    )
  }

  func testLoadingProfile() throws {
    let formatter = DateFormatter()
    formatter.dateFormat = "MM/dd/yyyy"
    var capturedProfile: Profile?
    var capturedError: Error?

    Profile.load(
      token: SampleAccessTokens.validToken,
      request: testGraphRequest
    ) {
      capturedProfile = $0
      capturedError = $1
    }

    let completion = try XCTUnwrap(testGraphRequest.capturedCompletionHandler)
    completion(nil, sampleGraphResult(), nil)
    XCTAssertNil(capturedError)
    let profile = try XCTUnwrap(capturedProfile, "capturedProfile should not be nil")
    XCTAssertEqual(profile.firstName, SampleUserProfiles.valid.firstName)
    XCTAssertEqual(profile.middleName, SampleUserProfiles.valid.middleName)
    XCTAssertEqual(profile.lastName, SampleUserProfiles.valid.lastName)
    XCTAssertEqual(profile.name, SampleUserProfiles.valid.name)
    XCTAssertEqual(profile.userID, SampleUserProfiles.valid.userID)
    XCTAssertEqual(profile.linkURL, SampleUserProfiles.valid.linkURL)
    XCTAssertEqual(profile.email, SampleUserProfiles.valid.email)
    XCTAssertEqual(profile.friendIDs, SampleUserProfiles.valid.friendIDs)
    XCTAssertEqual(
      formatter.string(from: profile.birthday ?? Date()),
      "01/01/1990"
    )
    XCTAssertEqual(profile.ageRange, SampleUserProfiles.valid.ageRange)
    XCTAssertEqual(profile.hometown, SampleUserProfiles.valid.hometown)
    XCTAssertEqual(profile.gender, SampleUserProfiles.valid.gender)
    XCTAssertEqual(profile.location, SampleUserProfiles.valid.location)
  }

  func testLoadingProfileWithInvalidLink() throws {
    let result = [
      "id": SampleUserProfiles.valid.userID,
      "first_name": SampleUserProfiles.valid.firstName,
      "middle_name": SampleUserProfiles.valid.middleName,
      "last_name": SampleUserProfiles.valid.lastName,
      "name": SampleUserProfiles.valid.name,
      "link": "   ",
      "email": SampleUserProfiles.valid.email
    ]
    var capturedProfile: Profile?
    var capturedError: Error?

    Profile.load(
      token: SampleAccessTokens.validToken,
      request: testGraphRequest
    ) {
      capturedProfile = $0
      capturedError = $1
    }

    let completion = try XCTUnwrap(testGraphRequest.capturedCompletionHandler)
    completion(nil, result, nil)
    XCTAssertNil(capturedError)
    let profile = try XCTUnwrap(capturedProfile, "capturedProfile should not be nil")
    XCTAssertNil(profile.linkURL)
  }

  func testProfileNilWithNilAccessToken() {
    var capturedProfile: Profile?
    var capturedError: Error?

    Profile.load(
      token: nil,
      request: testGraphRequest
    ) {
      capturedProfile = $0
      capturedError = $1
    }
    XCTAssertEqual(
      testGraphRequest.startCallCount,
      0,
      "Should not fetch a profile if there is no access token"
    )
    XCTAssertNil(capturedProfile)
    XCTAssertNil(capturedError)
  }

  func testLoadingProfileWithNoFriends() throws {
    let result: [String: Any] = [
      "id": SampleUserProfiles.valid.userID,
      "first_name": SampleUserProfiles.valid.firstName as Any,
      "middle_name": SampleUserProfiles.valid.middleName as Any,
      "last_name": SampleUserProfiles.valid.lastName as Any,
      "name": SampleUserProfiles.valid.name as Any,
      "link": SampleUserProfiles.valid.linkURL as Any,
      "email": SampleUserProfiles.valid.email as Any,
      "friends": ["data": []
      ]
    ]
    var capturedProfile: Profile?
    var capturedError: Error?

    Profile.load(
      token: SampleAccessTokens.validToken,
      request: testGraphRequest
    ) {
      capturedProfile = $0
      capturedError = $1
    }

    let completion = try XCTUnwrap(testGraphRequest.capturedCompletionHandler)
    completion(nil, result, nil)
    XCTAssertNil(capturedError)
    let profile = try XCTUnwrap(capturedProfile, "capturedProfile should not be nil")
    XCTAssertNil(profile.friendIDs)
  }

  func testLoadingProfileWithInvalidFriends() throws {
    let result: [String: Any] = [
      "id": SampleUserProfiles.valid.userID,
      "first_name": SampleUserProfiles.valid.firstName as Any,
      "middle_name": SampleUserProfiles.valid.middleName as Any,
      "last_name": SampleUserProfiles.valid.lastName as Any,
      "name": SampleUserProfiles.valid.name as Any,
      "link": SampleUserProfiles.valid.linkURL as Any,
      "email": SampleUserProfiles.valid.email as Any,
      "friends": "   "
    ]
    var capturedProfile: Profile?
    var capturedError: Error?

    Profile.load(
      token: SampleAccessTokens.validToken,
      request: testGraphRequest
    ) {
      capturedProfile = $0
      capturedError = $1
    }

    let completion = try XCTUnwrap(testGraphRequest.capturedCompletionHandler)
    completion(nil, result, nil)
    XCTAssertNil(capturedError)
    let profile = try XCTUnwrap(capturedProfile, "capturedProfile should not be nil")
    XCTAssertNil(profile.friendIDs)
  }

  func testLoadingProfileWithInvalidBirthday() throws {
    let result: [String: Any] = [
      "id": SampleUserProfiles.valid.userID,
      "first_name": SampleUserProfiles.valid.firstName as Any,
      "middle_name": SampleUserProfiles.valid.middleName as Any,
      "last_name": SampleUserProfiles.valid.lastName as Any,
      "name": SampleUserProfiles.valid.name as Any,
      "link": SampleUserProfiles.valid.linkURL as Any,
      "email": SampleUserProfiles.valid.email as Any,
      "birthday": 123
    ]
    var capturedProfile: Profile?
    var capturedError: Error?

    Profile.load(
      token: SampleAccessTokens.validToken,
      request: testGraphRequest
    ) {
      capturedProfile = $0
      capturedError = $1
    }

    let completion = try XCTUnwrap(testGraphRequest.capturedCompletionHandler)
    completion(nil, result, nil)
    XCTAssertNil(capturedError)
    let profile = try XCTUnwrap(capturedProfile, "capturedProfile should not be nil")
    XCTAssertNil(profile.birthday)
  }

  func testLoadingProfileWithInvalidAgeRange() throws {
    let result: [String: Any] = [
      "id": SampleUserProfiles.valid.userID,
      "first_name": SampleUserProfiles.valid.firstName as Any,
      "middle_name": SampleUserProfiles.valid.middleName as Any,
      "last_name": SampleUserProfiles.valid.lastName as Any,
      "name": SampleUserProfiles.valid.name as Any,
      "link": SampleUserProfiles.valid.linkURL as Any,
      "email": SampleUserProfiles.valid.email as Any,
      "age_range": "ageRange"
    ]
    var capturedProfile: Profile?
    var capturedError: Error?

    Profile.load(
      token: SampleAccessTokens.validToken,
      request: testGraphRequest
    ) {
      capturedProfile = $0
      capturedError = $1
    }

    let completion = try XCTUnwrap(testGraphRequest.capturedCompletionHandler)
    completion(nil, result, nil)
    XCTAssertNil(capturedError)
    let profile = try XCTUnwrap(capturedProfile, "capturedProfile should not be nil")
    XCTAssertNil(profile.ageRange)
  }

  func testLoadingProfileWithInvalidHometown() throws {
    let result: [String: Any] = [
      "id": SampleUserProfiles.valid.userID,
      "first_name": SampleUserProfiles.valid.firstName as Any,
      "middle_name": SampleUserProfiles.valid.middleName as Any,
      "last_name": SampleUserProfiles.valid.lastName as Any,
      "name": SampleUserProfiles.valid.name as Any,
      "link": SampleUserProfiles.valid.linkURL as Any,
      "email": SampleUserProfiles.valid.email as Any,
      "hometown": "hometown"
    ]
    var capturedProfile: Profile?
    var capturedError: Error?

    Profile.load(
      token: SampleAccessTokens.validToken,
      request: testGraphRequest
    ) {
      capturedProfile = $0
      capturedError = $1
    }

    let completion = try XCTUnwrap(testGraphRequest.capturedCompletionHandler)
    completion(nil, result, nil)
    XCTAssertNil(capturedError)
    let profile = try XCTUnwrap(capturedProfile, "capturedProfile should not be nil")
    XCTAssertNil(profile.hometown)
  }

  func testLoadingProfileWithInvalidLocation() throws {
    let result: [String: Any] = [
      "id": SampleUserProfiles.valid.userID,
      "first_name": SampleUserProfiles.valid.firstName as Any,
      "middle_name": SampleUserProfiles.valid.middleName as Any,
      "last_name": SampleUserProfiles.valid.lastName as Any,
      "name": SampleUserProfiles.valid.name as Any,
      "link": SampleUserProfiles.valid.linkURL as Any,
      "email": SampleUserProfiles.valid.email as Any,
      "location": "location"
    ]
    var capturedProfile: Profile?
    var capturedError: Error?

    Profile.load(
      token: SampleAccessTokens.validToken,
      request: testGraphRequest
    ) {
      capturedProfile = $0
      capturedError = $1
    }

    let completion = try XCTUnwrap(testGraphRequest.capturedCompletionHandler)
    completion(nil, result, nil)
    XCTAssertNil(capturedError)
    let profile = try XCTUnwrap(capturedProfile, "capturedProfile should not be nil")
    XCTAssertNil(profile.location)
  }

  func testLoadingProfileWithInvalidGender() throws {
    let result: [String: Any] = [
      "id": SampleUserProfiles.valid.userID,
      "first_name": SampleUserProfiles.valid.firstName as Any,
      "middle_name": SampleUserProfiles.valid.middleName as Any,
      "last_name": SampleUserProfiles.valid.lastName as Any,
      "name": SampleUserProfiles.valid.name as Any,
      "link": SampleUserProfiles.valid.linkURL as Any,
      "email": SampleUserProfiles.valid.email as Any,
      "gender": [:]
    ]
    var capturedProfile: Profile?
    var capturedError: Error?

    Profile.load(
      token: SampleAccessTokens.validToken,
      request: testGraphRequest
    ) {
      capturedProfile = $0
      capturedError = $1
    }

    let completion = try XCTUnwrap(testGraphRequest.capturedCompletionHandler)
    completion(nil, result, nil)
    XCTAssertNil(capturedError)
    let profile = try XCTUnwrap(capturedProfile, "capturedProfile should not be nil")
    XCTAssertNil(profile.gender)
  }

  func testProfileNotRefreshedIfNotStale() throws {
    Profile.current = SampleUserProfiles.valid
    var capturedProfile: Profile?
    var capturedError: Error?

    Profile.load(
      token: nil,
      request: testGraphRequest
    ) {
      capturedProfile = $0
      capturedError = $1
    }
    XCTAssertEqual(
      testGraphRequest.startCallCount,
      0,
      "Should not fetch a profile if it is not stale"
    )
    XCTAssertNil(capturedError)
    let profile = try XCTUnwrap(capturedProfile, "capturedProfile should not be nil")
    XCTAssertEqual(profile.firstName, SampleUserProfiles.valid.firstName)
    XCTAssertEqual(profile.middleName, SampleUserProfiles.valid.middleName)
    XCTAssertEqual(profile.lastName, SampleUserProfiles.valid.lastName)
    XCTAssertEqual(profile.name, SampleUserProfiles.valid.name)
    XCTAssertEqual(profile.userID, SampleUserProfiles.valid.userID)
    XCTAssertEqual(profile.linkURL, SampleUserProfiles.valid.linkURL)
    XCTAssertEqual(profile.email, SampleUserProfiles.valid.email)
  }

  func testLoadingProfileWithLimitedProfileWithoutToken() throws {
    let expected = SampleUserProfiles.validLimited
    Profile.current = expected
    let request = TestGraphRequest()
    var capturedProfile: Profile?
    var capturedError: Error?

    Profile.load(
      token: nil,
      request: testGraphRequest
    ) {
      capturedProfile = $0
      capturedError = $1
    }

    XCTAssertEqual(
      request.startCallCount,
      0,
      "Should not fetch a profile if there is no access token"
    )
    XCTAssertNil(capturedError)
    let profile = try XCTUnwrap(capturedProfile, "capturedProfile should not be nil")
    XCTAssertEqual(
      profile,
      expected,
      "Should return the current profile synchronously"
    )
  }

  func testLoadingProfileWithLimitedProfileWithToken() {
    Profile.current = SampleUserProfiles.validLimited
    let request = TestGraphRequest()
    Profile.load(
      token: SampleAccessTokens.validToken,
      request: request
    ) { _, _ in
      XCTFail("Should not invoke the completion")
    }
    XCTAssertEqual(
      request.startCallCount,
      1,
      "Should fetch a profile if it is limited and there is an access token"
    )
  }

  func testLoadingProfileWithExpiredNonLimitedProfileWithToken() {
    let expected = SampleUserProfiles.createValid(isExpired: true)
    Profile.current = expected
    let request = TestGraphRequest()
    Profile.load(
      token: SampleAccessTokens.validToken,
      request: request
    ) { _, _ in
      XCTFail("Should not invoke the completion")
    }
    XCTAssertEqual(
      request.startCallCount,
      1,
      "Should fetch a profile if it is expired and there is an access token"
    )
  }

  func testLoadingProfileWithCurrentlyLoadingProfile() {
    let expected = SampleUserProfiles.createValid(isExpired: true)
    Profile.current = expected
    let request = TestGraphRequest()
    let connection = TestGraphRequestConnection()
    request.stubbedConnection = connection
    Profile.load(
      token: SampleAccessTokens.validToken,
      request: request
    ) { _, _ in
      XCTFail("Should not invoke the completion")
    }
    Profile.load(
      token: SampleAccessTokens.validToken,
      request: request
    ) { _, _ in
      XCTFail("Should not invoke the completion")
    }
    XCTAssertEqual(
      connection.cancelCallCount,
      1,
      "Should cancel an existing connection if a new connection is started before it completes"
    )
  }

  func testProfileParseBlockInvokedOnSuccessfulGraphRequest() throws {
    let result: [String: String] = [:]
    var capturedProfileRef: AutoreleasingUnsafeMutablePointer<Profile>?
    var capturedResult: Any?
    Profile.load(
      with: SampleAccessTokens.validToken,
      graphRequest: testGraphRequest,
      completion: { _, _ in },
      parseBlock: {
        capturedResult = $0
        capturedProfileRef = $1
      }
    )
    let completion = try XCTUnwrap(testGraphRequest.capturedCompletionHandler)
    completion(nil, result, nil)
    XCTAssertNotNil(capturedProfileRef)
    XCTAssertNotNil(capturedResult)
  }

  func testProfileParseBlockShouldHaveNonNullPointer() throws {
    let result: [String: String] = [:]
    var capturedProfileRef: AutoreleasingUnsafeMutablePointer<Profile>?
    var capturedResult: Any?
    Profile.load(
      with: SampleAccessTokens.validToken,
      graphRequest: testGraphRequest,
      completion: { _, _ in },
      parseBlock: {
        capturedResult = $0
        capturedProfileRef = $1
      }
    )
    let completion = try XCTUnwrap(testGraphRequest.capturedCompletionHandler)
    completion(nil, result, nil)
    XCTAssertNotNil(capturedProfileRef)
    XCTAssertNotNil(capturedResult)
  }

  func testProfileParseBlockReturnsNilIfResultIsEmpty() throws {
    let result: [String: String] = [:]
    Profile.load(token: SampleAccessTokens.validToken, request: testGraphRequest, completion: nil)

    let completion = try XCTUnwrap(testGraphRequest.capturedCompletionHandler)
    completion(nil, result, nil)
    XCTAssertNil(Profile.current)
  }

  func testProfileParseBlockReturnsNilIfResultHasNoId() throws {
    let result = [
      "first_name": "firstname",
      "middle_name": "middlename",
      "last_name": "lastname",
      "name": "name"
    ]
    Profile.load(token: SampleAccessTokens.validToken, request: testGraphRequest, completion: nil)
    let completion = try XCTUnwrap(testGraphRequest.capturedCompletionHandler)
    completion(nil, result, nil)
    XCTAssertNil(Profile.current)
  }

  func testProfileParseBlockReturnsNilIfResultHasEmptyId() throws {
    let result = [
      "id": "",
      "first_name": "firstname",
      "middle_name": "middlename",
      "last_name": "lastname",
      "name": "name"
    ]
    Profile.load(token: SampleAccessTokens.validToken, request: testGraphRequest, completion: nil)
    let completion = try XCTUnwrap(testGraphRequest.capturedCompletionHandler)
    completion(nil, result, nil)
    XCTAssertNil(Profile.current)
  }

  func testLoadProfileWithRandomData() throws {
    for _ in 0..<100 {
      let randomizedResult = Fuzzer.randomize(json: sampleGraphResult())
      var completed = false
      Profile.load(
        token: SampleAccessTokens.validToken,
        request: testGraphRequest
      ) { _, _ in
        completed = true
      }
      let completion = try XCTUnwrap(testGraphRequest.capturedCompletionHandler)
      completion(nil, randomizedResult, nil)
      XCTAssert(completed, "Completion handler should be invoked synchronously")
    }
  }

  // MARK: Storage

  // swiftlint:disable:next function_body_length
  func testEncoding() {
    let coder = TestCoder()
    let profile = SampleUserProfiles.validLimited
    profile.encode(with: coder)

    XCTAssertEqual(
      coder.encodedObject["userID"] as? String,
      profile.userID,
      "Should encode the expected user identifier"
    )
    XCTAssertEqual(
      coder.encodedObject["firstName"] as? String,
      profile.firstName,
      "Should encode the expected first name"
    )
    XCTAssertEqual(
      coder.encodedObject["middleName"] as? String,
      profile.middleName,
      "Should encode the expected middle name"
    )
    XCTAssertEqual(
      coder.encodedObject["lastName"] as? String,
      profile.lastName,
      "Should encode the expected last name"
    )
    XCTAssertEqual(
      coder.encodedObject["name"] as? String,
      profile.name,
      "Should encode the expected name"
    )
    XCTAssertEqual(
      coder.encodedObject["linkURL"] as? URL,
      profile.linkURL,
      "Should encode the expected link URL"
    )
    XCTAssertEqual(
      coder.encodedObject["refreshDate"] as? Date,
      profile.refreshDate,
      "Should encode the expected refresh date"
    )
    XCTAssertEqual(
      coder.encodedObject["imageURL"] as? URL,
      profile.imageURL,
      "Should encode the expected image URL"
    )
    XCTAssertEqual(
      coder.encodedObject["email"] as? String,
      profile.email,
      "Should encode the expected email address"
    )
    XCTAssertEqual(
      coder.encodedObject["friendIDs"] as? [String],
      profile.friendIDs,
      "Should encode the expected list of friend identifiers"
    )
    XCTAssertEqual(
      coder.encodedObject["birthday"] as? Date,
      profile.birthday,
      "Should encode the expected user birthday"
    )
    XCTAssertEqual(
      coder.encodedObject["ageRange"] as? UserAgeRange,
      profile.ageRange,
      "Should encode the expected user age range"
    )
    XCTAssertEqual(
      coder.encodedObject["hometown"] as? Location,
      profile.hometown,
      "Should encode the expected user hometown"
    )
    XCTAssertEqual(
      coder.encodedObject["location"] as? Location,
      profile.location,
      "Should encode the expected user location"
    )
    XCTAssertEqual(
      coder.encodedObject["gender"] as? String,
      profile.gender,
      "Should encode the expected user gender"
    )
    XCTAssertEqual(
      coder.encodedObject["isLimited"] as? Bool,
      true,
      "isLimited should be true"
    )
  }

  // swiftlint:disable:next function_body_length
  func testDecodingEntryWithMethodName() {
    let coder = TestCoder()
    _ = Profile(coder: coder)

    XCTAssertTrue(
      coder.decodedObject["userID"].self as? Any.Type == NSString.self,
      "Should decode a string for the userID key"
    )
    XCTAssertTrue(
      coder.decodedObject["firstName"].self as? Any.Type == NSString.self,
      "Should decode a string for the firstName key"
    )
    XCTAssertTrue(
      coder.decodedObject["middleName"].self as? Any.Type == NSString.self,
      "Should decode a string for the middleName key"
    )
    XCTAssertTrue(
      coder.decodedObject["lastName"].self as? Any.Type == NSString.self,
      "Should decode a string for the lastName key"
    )
    XCTAssertTrue(
      coder.decodedObject["name"].self as? Any.Type == NSString.self,
      "Should decode a string for the name key"
    )
    XCTAssertTrue(
      coder.decodedObject["linkURL"].self as? Any.Type == NSURL.self,
      "Should decode a url for the linkURL key"
    )
    XCTAssertTrue(
      coder.decodedObject["refreshDate"].self as? Any.Type == NSDate.self,
      "Should decode a date for the refreshDate key"
    )
    XCTAssertTrue(
      coder.decodedObject["imageURL"].self as? Any.Type == NSURL.self,
      "Should decode a url for the imageURL key"
    )
    XCTAssertTrue(
      coder.decodedObject["email"].self as? Any.Type == NSString.self,
      "Should decode a string for the email key"
    )
    XCTAssertTrue(
      coder.decodedObject["friendIDs"].self as? Any.Type == NSArray.self,
      "Should decode an array for the friendIDs key"
    )
    XCTAssertTrue(
      coder.decodedObject["birthday"].self as? Any.Type == NSDate.self,
      "Should decode a date for the birthday key"
    )
    XCTAssertTrue(
      coder.decodedObject["ageRange"].self as? Any.Type == UserAgeRange.self,
      "Should decode a UserAgeRange object for the ageRange key"
    )
    XCTAssertTrue(
      coder.decodedObject["hometown"].self as? Any.Type == Location.self,
      "Should decode a Location object for the hometown key"
    )
    XCTAssertTrue(
      coder.decodedObject["location"].self as? Any.Type == Location.self,
      "Should decode a Location object for the location key"
    )
    XCTAssertTrue(
      coder.decodedObject["gender"].self as? Any.Type == NSString.self,
      "Should decode a string for the gender key"
    )
    XCTAssertEqual(
      coder.decodedObject["isLimited"] as? String,
      "decodeBoolForKey",
      "Should decode a boolean for the isLimited key"
    )
  }

  func testDefaultStore() {
    Profile.reset()
    XCTAssertNil(
      Profile.store,
      "Should not have a default data store"
    )
  }

  func testConfiguringWithStore() {
    XCTAssertTrue(
      Profile.store === store,
      "Should be able to set a persistent data store"
    )
  }

  func testConfiguringWithNotificationCenter() {
    XCTAssertTrue(
      Profile.notificationCenter === notificationCenter,
      "Should be able to set a Notification Posting"
    )
  }

  func testDefaultAccessTokenProvider() {
    Profile.reset()
    XCTAssertNil(
      Profile.accessTokenProvider,
      "Should not have a default access token provider"
    )
  }

  func testConfiguringWithTokenProvider() {
    XCTAssertTrue(
      Profile.accessTokenProvider is TestAccessTokenWallet.Type,
      "Should be able to set a token wallet"
    )
  }

  func testDefaultSettings() {
    Profile.reset()
    XCTAssertNil(
      Profile.settings,
      "Should not have default settings"
    )
  }

  func testConfiguringWithSettings() {
    XCTAssertTrue(
      Profile.settings === settings,
      "Should be able to set settings"
    )
  }

  func testHashability() {
    let profile = SampleUserProfiles.createValid()
    let profile2 = SampleUserProfiles.createValid(userID: name)

    XCTAssertEqual(
      profile.hash,
      profile.hash,
      "Hashed profiles should be consistent"
    )
    XCTAssertNotEqual(
      profile.hash,
      profile2.hash,
      "Hashed profiles should be unique"
    )
  }

  func testFetchingCachedProfile() {
    _ = Profile.fetchCachedProfile()

    XCTAssertEqual(
      store.capturedObjectRetrievalKey,
      "com.facebook.sdk.FBSDKProfile.currentProfile",
      "Fetching a cached profile should query the store with the expected retrieval key"
    )
  }

  func sampleGraphResult() -> [String: Any] {
    [
      "id": SampleUserProfiles.valid.userID,
      "first_name": SampleUserProfiles.valid.firstName as Any,
      "middle_name": SampleUserProfiles.valid.middleName as Any,
      "last_name": SampleUserProfiles.valid.lastName as Any,
      "name": SampleUserProfiles.valid.name as Any,
      "link": SampleUserProfiles.valid.linkURL as Any,
      "email": SampleUserProfiles.valid.email as Any,
      "friends": ["data": [
        [
          "name": "user1",
          "id": SampleUserProfiles.valid.friendIDs?[0]
        ],
        [
          "name": "user2",
          "id": SampleUserProfiles.valid.friendIDs?[1]
        ]
      ]],
      "birthday": "01/01/1990",
      "age_range": [
        "min": SampleUserProfiles.valid.ageRange?.min
      ],
      "hometown": [
        "id": SampleUserProfiles.valid.hometown?.id,
        "name": SampleUserProfiles.valid.hometown?.name
      ],
      "location": [
        "id": SampleUserProfiles.valid.location?.id,
        "name": SampleUserProfiles.valid.location?.name
      ],
      "gender": SampleUserProfiles.valid.gender as Any
    ]
  }

  func verfiyGraphPath(
    expectedPath: String,
    permissions: [String],
    file: StaticString = #file,
    line: UInt = #line
  ) {
    let token = SampleAccessTokens.create(withPermissions: permissions)
    let graphPath = Profile.graphPath(for: token)
    XCTAssertEqual(graphPath, expectedPath, file: file, line: line)
  }
}
// swiftlint:disable:this file_length
