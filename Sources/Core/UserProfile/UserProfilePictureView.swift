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

import FBSDKCoreKit.FBSDKProfilePictureView

/// A view to display a profile picture.
public class UserProfilePictureView: UIView {

  private let sdkProfilePictureView = FBSDKProfilePictureView(frame: .zero)

  /// The aspect ratio of the source image of the profile picture.
  public var pictureAspectRatio = UserProfile.PictureAspectRatio.Square {
    didSet {
      sdkProfilePictureView.pictureMode = pictureAspectRatio.sdkPictureMode
    }
  }

  /// The user id to show the picture for.
  public var userId = "me" {
    didSet {
      sdkProfilePictureView.profileID = userId
    }
  }

  /**
   Create a new instance of `UserProfilePictureView`.

   - parameter frame:   Optional frame rectangle for the view, measured in points.
   - parameter profile: Optional profile to display a picture for. Default: `UserProfile.current`.
   */
  public init(frame: CGRect = .zero, profile: UserProfile? = nil) {
    super.init(frame: frame)

    if let profile = profile {
      userId = profile.userId
    }
    setupSDKProfilePictureView()
  }

  /**
   Create a new instance of `UserProfilePictureView` from an encoded interface file.

   - parameter decoder: The coder to initialize from.
   */
  public required init?(coder decoder: NSCoder) {
    super.init(coder: decoder)
    setupSDKProfilePictureView()
  }

  /**
   Explicitly marks the receiver as needing to update the image.

   This method is called whenever any properties that affect the source image are modified,
   but this can also be used to trigger a manual update of the image if it needs to be re-downloaded.
   */
  public func setNeedsImageUpdate() {
    sdkProfilePictureView.setNeedsImageUpdate()
  }
}

extension UserProfilePictureView {
  private func setupSDKProfilePictureView() {
    sdkProfilePictureView.frame = bounds
    sdkProfilePictureView.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
    addSubview(sdkProfilePictureView)
    setNeedsImageUpdate() // Trigger the update to refresh the image, just in case.
  }
}
