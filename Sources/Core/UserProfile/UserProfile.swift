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

import Foundation
import UIKit
import FBSDKCoreKit.FBSDKProfile

//--------------------------------------
// MARK: - UserProfile
//--------------------------------------

/**
 Represents an immutable Facebook profile.

 This class provides a global `current` instance to more easily add social context to your application.
 When the profile changes, a notification is posted so that you can update relevant parts of your UI and is persisted to `NSUserDefaults`.

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
  public let profileURL: NSURL?

  /// The last time the profile was refreshed.
  public let refreshDate: NSDate

  /**
   Creates a new instance of `Profile`.

   - parameter userId:      The user id.
   - parameter firstName:   Optional user's first name.
   - parameter middleName:  Optional user's middle name.
   - parameter lastName:    Optional user's last name.
   - parameter fullName:    Optional user's full name.
   - parameter profileURL:  Optional user's profile URL.
   - parameter refreshDate: Optional user's last refresh date. Default: `NSDate()` aka current date/time.
   */
  public init(userId: String,
              firstName: String? = nil,
              middleName: String? = nil,
              lastName: String? = nil,
              fullName: String? = nil,
              profileURL: NSURL? = nil,
              refreshDate: NSDate = NSDate()) {
    self.userId = userId
    self.firstName = firstName
    self.middleName = middleName
    self.lastName = lastName
    self.fullName = fullName
    self.profileURL = profileURL
    self.refreshDate = refreshDate
  }
}

//--------------------------------------
// MARK: - Current Profile
//--------------------------------------

extension UserProfile {
  /**
   Current instance of `Profile` that represents the currently logged in user's profile.
   */
  public static var current: UserProfile? {
    get {
      let sdkProfile = FBSDKProfile.currentProfile() as FBSDKProfile?
      return sdkProfile.map(UserProfile.init)
    }
    set {
      FBSDKProfile.setCurrentProfile(newValue?.sdkProfileRepresentation)
    }
  }

  /**
   Loads the current profile and passes it to the completion closure.

   If the `current` profile is already loaded, this method will call the completion block synchronously,
   otherwise it will begin a graph request to update `current` profile and the call the completion closure when finished.

   - parameter completion: The closure to be executed once the profile is loaded.
   */
  public static func loadCurrent(completion: ((UserProfile?, ErrorType?) -> Void)?) {
    FBSDKProfile.loadCurrentProfileWithCompletion { (profile: FBSDKProfile?, error: NSError?) in
      completion?(profile.map(UserProfile.init), error)
    }
  }

  private static var _updatesOnAccessTokenChange: Bool = false
  /**
   Allows controlling whether `current` profile should automatically update when `AccessToken.current` changes.

   - note: If `AccessToken.current` is unset (changes to `nil`), the `current` profile instance remains.
   It's also possible for the `current` to return `nil` until the data is fetched.
   */
  public static var updatesOnAccessTokenChange: Bool {
    get {
      return _updatesOnAccessTokenChange
    }
    set {
      _updatesOnAccessTokenChange = newValue
      FBSDKProfile.enableUpdatesOnAccessTokenChange(newValue)
    }
  }
}

//--------------------------------------
// MARK: - Profile Picture
//--------------------------------------

extension UserProfile {
  /**
   Defines the aspect ratio for the source image of the profile picture.
   */
  public enum PictureAspectRatio {
    /// A square cropped version of the profile picture.
    case Square
    /// The original picture's aspect ratio.
    case Normal

    internal var sdkPictureMode: FBSDKProfilePictureMode {
      switch self {
      case Square: return .Square
      case Normal: return .Normal
      }
    }
  }

  /**
   Returns a complete `NSURL` for retrieving the user's profile image.

   - parameter aspectRatio: Apsect ratio of the source image to use.
   - parameter size:        Requested height and width of the image. Will be rounded to integer precision.
   */
  public func imageURLWith(aspectRatio: PictureAspectRatio, size: CGSize) -> NSURL {
    return sdkProfileRepresentation.imageURLForPictureMode(aspectRatio.sdkPictureMode, size: size)
  }
}

//--------------------------------------
// MARK: - Internal
//--------------------------------------

extension UserProfile {
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
