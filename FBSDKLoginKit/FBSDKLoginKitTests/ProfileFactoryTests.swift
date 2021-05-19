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

import FBSDKLoginKit
import TestTools
import XCTest

class ProfileFactoryTests: XCTestCase {

  let expected = Profile(
    userID: SampleUserProfiles.valid.userID,
    firstName: SampleUserProfiles.valid.firstName,
    middleName: SampleUserProfiles.valid.middleName,
    lastName: SampleUserProfiles.valid.lastName,
    name: SampleUserProfiles.valid.name,
    linkURL: SampleUserProfiles.valid.linkURL,
    refreshDate: SampleUserProfiles.valid.refreshDate,
    imageURL: SampleUserProfiles.valid.imageURL,
    email: SampleUserProfiles.valid.email,
    friendIDs: SampleUserProfiles.valid.friendIDs,
    birthday: SampleUserProfiles.valid.birthday,
    ageRange: SampleUserProfiles.valid.ageRange,
    hometown: SampleUserProfiles.valid.hometown,
    location: SampleUserProfiles.valid.location,
    gender: SampleUserProfiles.valid.gender,
    isLimited: true
  )
  let factory = ProfileFactory()

  func testCreatingProfile() {
    let profile = factory.createProfile(
      userID: SampleUserProfiles.valid.userID,
      firstName: SampleUserProfiles.valid.firstName,
      middleName: SampleUserProfiles.valid.middleName,
      lastName: SampleUserProfiles.valid.lastName,
      name: SampleUserProfiles.valid.name,
      linkURL: SampleUserProfiles.valid.linkURL,
      refreshDate: SampleUserProfiles.valid.refreshDate,
      imageURL: SampleUserProfiles.valid.imageURL,
      email: SampleUserProfiles.valid.email,
      friendIDs: SampleUserProfiles.valid.friendIDs,
      birthday: SampleUserProfiles.valid.birthday,
      ageRange: SampleUserProfiles.valid.ageRange,
      hometown: SampleUserProfiles.valid.hometown,
      location: SampleUserProfiles.valid.location,
      gender: SampleUserProfiles.valid.gender,
      isLimited: true
    )
    XCTAssertEqual(profile.userID, expected.userID)
    XCTAssertEqual(profile.firstName, expected.firstName)
    XCTAssertEqual(profile.middleName, expected.middleName)
    XCTAssertEqual(profile.lastName, expected.lastName)
    XCTAssertEqual(profile.name, expected.name)
    XCTAssertEqual(profile.linkURL, expected.linkURL)
    XCTAssertEqual(profile.refreshDate, expected.refreshDate)
    XCTAssertEqual(profile.imageURL, expected.imageURL)
    XCTAssertEqual(profile.email, expected.email)
    XCTAssertEqual(profile.friendIDs, expected.friendIDs)
    XCTAssertEqual(profile.birthday, expected.birthday)
    XCTAssertEqual(profile.ageRange, expected.ageRange)
    XCTAssertEqual(profile.hometown, expected.hometown)
    XCTAssertEqual(profile.location, expected.location)
    XCTAssertEqual(profile.gender, expected.gender)
  }
}
