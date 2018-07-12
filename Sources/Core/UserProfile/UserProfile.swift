// Copyright (c) 2016-present, Facebook, Inc. All rights reserved.
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

import FBSDKCoreKit.FBSDKProfile
import Foundation
import UIKit

//--------------------------------------
// MARK: - UserProfile
//--------------------------------------

/**
 Represents an immutable Facebook profile.

 This class provides a global `current` instance to more easily add social context to your application.
 When the profile changes, a notification is posted so that you can update relevant parts of your UI
 and is persisted to `NSUserDefaults`.

 Typically, you will want to call `Profile.updatesOnAccessTokenChange = true`,
 so that it automatically observes changes to the `AccessToken.current`.

 You can use this class to build your own `ProfilePictureView` or in place of typical requests to "/me".
 */
public struct UserProfile {
  /// The user id.
  public let userId: String

  /// The user's first name.
  public let firstName: String?

  /// The user's middle name.
  public let middleName: String?

  /// The user's last name.
  public let lastName: String?

  /// The user's complete name.
  public let fullName: String?

  /// A URL to the user's profile.
  public let profileURL: URL?

  /// The last time the profile was refreshed.
  public let refreshDate: Date

  /**
   Creates a new instance of `Profile`.

   - parameter userId: The user id.
   - parameter firstName: Optional user's first name.
   - parameter middleName: Optional user's middle name.
   - parameter lastName: Optional user's last name.
   - parameter fullName: Optional user's full name.
   - parameter profileURL: Optional user's profile URL.
   - parameter refreshDate: Optional user's last refresh date. Default: `NSDate()` aka current date/time.
   */
  public init(userId: String,
              firstName: String? = nil,
              middleName: String? = nil,
              lastName: String? = nil,
              fullName: String? = nil,
              profileURL: URL? = nil,
              refreshDate: Date = Date()) {
    self.userId = userId
    self.firstName = firstName
    self.middleName = middleName
    self.lastName = lastName
    self.fullName = fullName
    self.profileURL = profileURL
    self.refreshDate = refreshDate
  }

  //--------------------------------------
  // MARK: - Loading Profile
  //--------------------------------------

  /// Convenience alias for type of closure that is used as a completion for fetching `UserProfile`.
  public typealias Completion = (FetchResult) -> Void

  /**
   Fetches a user profile by userId.

   If the `current` profile is set, and it has the same `userId`,
   calling method will reset the current profile with the newly fetched one.

   - parameter userId: Facebook user id of the profile to fetch.
   - parameter completion: The closure to be executed once the profile is refreshed.
   */
  public static func fetch(userId: String, completion: @escaping Completion) {
    let request = GraphRequest(graphPath: userId,
                               parameters: ["fields": "first_name,middle_name,last_name,name,link"],
                               httpMethod: .GET)
    request.start { _, result in
      switch result {
      case .success(let response):
        let responseDictionary = response.dictionaryValue

        let profile = UserProfile(userId: userId,
                                  firstName: responseDictionary?["first_name"] as? String,
                                  middleName: responseDictionary?["middle_name"] as? String,
                                  lastName: responseDictionary?["last_name"] as? String,
                                  fullName: responseDictionary?["name"] as? String,
                                  profileURL: (responseDictionary?["link"] as? String).flatMap({ URL(string: $0) }),
                                  refreshDate: Date())

        // Reset the current profile if userId matches
        if AccessToken.current?.userId == userId {
          UserProfile.current = profile
        }
        completion(.success(profile))

      case .failed(let error):
        completion(.failed(error))
      }
    }
  }

  /**
   Refreshes the existing user profile.

   If the `current` profile is set, and receiver has the same `userId`,
   calling method will reset the current profile with the newly fetched one.

   - parameter completion: Optional closure to be executed once the profile is refreshed. Default: `nil`.
   */
  public func refresh(_ completion: Completion?) {
    UserProfile.fetch(userId: userId) { result in
      completion?(result)
    }
  }

  //--------------------------------------
  // MARK: - Current Profile
  //--------------------------------------

  /**
   Current instance of `Profile` that represents the currently logged in user's profile.
   */
  public static var current: UserProfile? {
    get {
      let sdkProfile = FBSDKProfile.current() as FBSDKProfile?
      return sdkProfile.map(UserProfile.init)
    }
    set {
      FBSDKProfile.setCurrent(newValue?.sdkProfileRepresentation)
    }
  }

  /**
   Loads the current profile and passes it to the completion closure.

   If the `current` profile is already loaded, this method will call the completion block synchronously,
   otherwise it will begin a graph request to update `current` profile
   and the call the completion closure when finished.

   - parameter completion: The closure to be executed once the profile is loaded.
   */
  public static func loadCurrent(_ completion: Completion?) {
    FBSDKProfile.loadCurrentProfile { (sdkProfile: FBSDKProfile?, error: Error?) in
      if let completion = completion {
        let result = FetchResult(sdkProfile: sdkProfile, error: error)
        completion(result)
      }
    }
  }

  /**
   Allows controlling whether `current` profile should automatically update when `AccessToken.current` changes.

   - note: If `AccessToken.current` is unset (changes to `nil`), the `current` profile instance remains.
   It's also possible for the `current` to return `nil` until the data is fetched.
   */
  public static var updatesOnAccessTokenChange: Bool = false {
    didSet {
      FBSDKProfile.enableUpdates(onAccessTokenChange: updatesOnAccessTokenChange)
    }
  }

  //--------------------------------------
  // MARK: - Profile Picture
  //--------------------------------------

  /**
   Defines the aspect ratio for the source image of the profile picture.
   */
  public enum PictureAspectRatio {
    /// A square cropped version of the profile picture.
    case square
    /// The original picture's aspect ratio.
    case normal

    internal var sdkPictureMode: FBSDKProfilePictureMode {
      switch self {
      case .square: return .square
      case .normal: return .normal
      }
    }
  }

  /**
   Returns a complete `NSURL` for retrieving the user's profile image.

   - parameter aspectRatio: Apsect ratio of the source image to use.
   - parameter size: Requested height and width of the image. Will be rounded to integer precision.
   */
  public func imageURLWith(_ aspectRatio: PictureAspectRatio, size: CGSize) -> URL {
    return sdkProfileRepresentation.imageURL(for: aspectRatio.sdkPictureMode, size: size)
  }

  //--------------------------------------
  // MARK: - Internal
  //--------------------------------------

  internal init(sdkProfile: FBSDKProfile) {
    self.init(userId: sdkProfile.userID,
              firstName: sdkProfile.firstName,
              middleName: sdkProfile.middleName,
              lastName: sdkProfile.lastName,
              fullName: sdkProfile.name,
              profileURL: sdkProfile.linkURL,
              refreshDate: sdkProfile.refreshDate)
  }

  internal var sdkProfileRepresentation: FBSDKProfile {
    return FBSDKProfile(userID: userId,
                        firstName: firstName,
                        middleName: middleName,
                        lastName: lastName,
                        name: fullName,
                        linkURL: profileURL,
                        refreshDate: refreshDate)
  }
}
