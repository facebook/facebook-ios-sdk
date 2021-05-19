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

@objcMembers
public class SampleUserProfiles: NSObject {

  public static let defaultName = "John Smith"
  public static let defaultImageUrl = URL(string: "http://www.example.com/image.jpg")
  public static let defaultUserID = "123"

  public class var valid: Profile {
    return Profile(
      userID: defaultUserID,
      firstName: "John",
      middleName: "K",
      lastName: "Smith",
      name: defaultName,
      linkURL: URL(string: "http://www.example.com"),
      refreshDate: .distantFuture,
      imageURL: defaultImageUrl,
      email: "example@example.com",
      friendIDs: [
        "456",
        "789",
      ],
      birthday: Date(timeIntervalSince1970: 0),
      ageRange: UserAgeRange(from: ["min": 21]),
      hometown: Location(from: ["id": "112724962075996", "name": "Martinez, California"]),
      location: Location(from: ["id": "110843418940484", "name": "Seattle, Washington"]),
      gender: "male"
    )
  }

  public static var missingImageUrl = createValid(imageURL: nil)
  public static var validLimited = createValid(isLimited: true)

  public static func createValid(userID: String) -> Profile {
    return createValid(userID: userID, name: defaultName)
  }

  public static func createValid(isExpired: Bool) -> Profile {
    return createValid(name: defaultName, isExpired: isExpired)
  }

  public static func createValid(
    userID: String = defaultUserID,
    name: String? = defaultName,
    imageURL url: URL? = defaultImageUrl,
    isExpired: Bool = false,
    isLimited: Bool = false
  ) -> Profile {
    return Profile(
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
      isLimited: isLimited
    )
  }
}
