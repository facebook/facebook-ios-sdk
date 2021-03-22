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
import Foundation

@objcMembers
public class TestProfileProvider: NSObject, ProfileProviding {

  public var capturedUserID: String?
  public var capturedFirstName: String?
  public var capturedMiddleName: String?
  public var capturedLastName: String?
  public var capturedName: String?
  public var capturedLinkURL: URL?
  public var capturedRefreshDate: Date?
  public var capturedImageURL: URL?
  public var capturedEmail: String?
  public var capturedFriendIDs: [String]?
  public var capturedBirthday: Date?
  public var capturedAgeRange: UserAgeRange?
  public var capturedIsLimited = false
  private var stubbedProfile: Profile

  public init(stubbedProfile: Profile) {
    self.stubbedProfile = stubbedProfile
  }

  public func createProfile( // swiftlint:disable:this function_parameter_count
    userID: String,
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
    isLimited: Bool
  ) -> Profile {
    capturedUserID = userID
    capturedFirstName = firstName
    capturedMiddleName = middleName
    capturedLastName = lastName
    capturedName = name
    capturedLinkURL = linkURL
    capturedRefreshDate = refreshDate
    capturedImageURL = imageURL
    capturedEmail = email
    capturedFriendIDs = friendIDs
    capturedBirthday = birthday
    capturedAgeRange = ageRange
    capturedIsLimited = isLimited

    return stubbedProfile
  }

}
