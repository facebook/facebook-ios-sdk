/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import UIKit

/// A view to display a profile picture.
@objcMembers
@objc(FBSDKProfilePictureView)
@available(tvOS, unavailable)
public final class FBProfilePictureView: UIView {

  /// The mode for the receiver to determine the aspect ratio of the source image.
  public var pictureMode: Profile.PictureMode = .square {
    didSet {
      if pictureMode != oldValue {
        setNeedsImageUpdate()
      }
    }
  }

  /// The profile ID to show the picture for.
  public var profileID: String {
    get {
      profilePictureID
    }

    set {
      if newValue != profilePictureID {
        profilePictureID = newValue
        placeholderImageIsValid = false
        setNeedsImageUpdate()
      }
    }
  }

  var currentState: ProfilePictureViewState {
    let shouldImageFit = shouldImageFit()
    let screen = window?.screen ?? UIScreen.main
    let scale = screen.scale
    let imageSize = getImageSize(imageShouldFit: shouldImageFit, scale: scale)
    return ProfilePictureViewState(
      profileID: profileID,
      size: imageSize,
      scale: scale,
      pictureMode: pictureMode,
      imageShouldFit: shouldImageFit
    )
  }

  var hasProfileImage = false
  var lastState: ProfilePictureViewState?
  var needsImageUpdate = false
  var placeholderImageIsValid = false
  var imageView = UIImageView(frame: .zero)
  private var profilePictureID = "me"

  public override var bounds: CGRect {
    get {
      super.bounds
    }
    set {
      DispatchQueue.main.async {
        let currentBounds = newValue
        if currentBounds != self.bounds {
          super.bounds = self.bounds
          if currentBounds.size != self.bounds.size {
            self.placeholderImageIsValid = false
            self.setNeedsImageUpdate()
          }
        }
      }
    }
  }

  public override var contentMode: UIView.ContentMode {
    get {
      imageView.contentMode
    }
    set {
      if imageView.contentMode != newValue {
        imageView.contentMode = newValue
        super.contentMode = newValue
        setNeedsImageUpdate()
      }
    }
  }

  // MARK: - Initialization

  /**
   Create a new instance.

   - Parameter frame: Frame rectangle for the view.
   - Parameter profile: Optional profile to display a picture for.
   */
  @objc(initWith:profile:)
  public init(frame: CGRect, profile: Profile? = nil) {
    super.init(frame: frame)
    profilePictureID = profile?.userID ?? "me"
    setNeedsImageUpdate()
  }

  /**
   Create a new instance.

   - Parameter profile: Optional profile to display a picture for.
   */
  @objc(initWithProfile:)
  public convenience init(profile: Profile? = nil) {
    self.init(frame: .zero, profile: profile)
  }

  /**
   Initializes and returns a newly allocated view object with the specified frame rectangle.

   - Parameter frame: The frame rectangle for the view, measured in points. The origin of the frame is relative to the superview in which you plan to add it.
   This method uses the frame rectangle to set the center and bounds properties accordingly.
   */
  @objc(initWithFrame:)
  public override init(frame: CGRect) {
    super.init(frame: frame)
    performInitialConfiguration()
  }

  /// Initializes and returns a newly allocated view object from the specified coder.
  @objc(initWithCoder:)
  public required init?(coder: NSCoder) {
    super.init(coder: coder)
    performInitialConfiguration()
  }

  /**
   Explicitly marks the receiver as needing to update the image.

   This method is called whenever any properties that affect the source image are modified, but this can also
   be used to trigger a manual update of the image if it needs to be re-downloaded.
   */
  public func setNeedsImageUpdate() {
    DispatchQueue.main.async { [self] in

      // we can't do anything with an empty view, so just bail out until we have a size
      guard
        imageView.superview != nil,
        !bounds.isEmpty
      else { return }

      // ensure that we have an image. Do this here,
      // so we can draw the placeholder image synchronously if we don't have one
      if !placeholderImageIsValid,
         !hasProfileImage {
        setPlaceholderImage()
      }

      // debounce calls to needsImage against the main runloop
      if needsImageUpdate {
        return
      }

      needsImageUpdate = true
      updateImage()
    }
  }

  func performInitialConfiguration() {
    imageView = UIImageView(frame: bounds)
    imageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    addSubview(imageView)
    backgroundColor = .white
    contentMode = .scaleAspectFit
    isUserInteractionEnabled = false
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(accessTokenDidChange),
      name: .AccessTokenDidChange,
      object: nil
    )

    NotificationCenter.default.addObserver(
      self,
      selector: #selector(profileDidChange),
      name: .ProfileDidChange,
      object: nil
    )
  }

  func accessTokenDidChange(_ notification: Notification) {
    guard profileID == "me",
          notification.userInfo?[AccessTokenDidChangeUserIDKey] != nil
    else {
      return
    }

    lastState = nil
    updateImageWithAccessToken()
  }

  func profileDidChange(_ notification: Notification) {
    guard profileID == "me" else {
      return
    }

    lastState = nil
    updateImageWithProfile()
  }

  func updateImageWithAccessToken() {
    let state = currentState
    if lastState != state {
      setPlaceholderImage()
    }

    if state.profileID == "me",
       !AccessToken.isCurrentAccessTokenActive {
      return
    }

    lastState = state
    if let imageURL = getProfileImageURL(state: state) {
      fetchAndSetImage(with: imageURL, state: state)
    }
  }

  func updateImageWithProfile() {
    let state = currentState
    // if the current image is no longer representative of the current state, clear the current value out; otherwise,
    // leave the current value until the new resolution image is downloaded
    if lastState != state {
      setPlaceholderImage()
    }

    let profile = Profile.current
    guard state.profileID == "me" else {
      return
    }

    if let imageURL = profile?.imageURL {
      lastState = state
      fetchAndSetImage(with: imageURL, state: state)
    }
  }

  func fetchAndSetImage(with imageURL: URL, state: ProfilePictureViewState) {
    let request = URLRequest(url: imageURL)

    URLSession.shared.dataTask(with: request) { [weak self] data, _, error in
      guard error == nil,
            let data = data else {
        return
      }

      self?.updateImage(data: data, state: state)
    }
    .resume()
  }

  func shouldImageFit() -> Bool {
    switch contentMode {
    case
      .bottom,
      .bottomLeft,
      .bottomRight,
      .center,
      .left,
      .redraw,
      .right,
      .scaleAspectFit,
      .top,
      .topLeft,
      .topRight:
      return true
    case
      .scaleAspectFill,
      .scaleToFill:
      return false
    @unknown default:
      return false
    }
  }

  func getImageSize(imageShouldFit: Bool, scale: CGFloat) -> CGSize {
    // get the image size based on the contentMode and pictureMode
    var size = bounds.size
    switch pictureMode {
    case .square:
      var imageSize: CGFloat
      if imageShouldFit {
        imageSize = min(size.width, size.height)
      } else {
        imageSize = max(size.width, size.height)
      }
      size = CGSize(width: imageSize, height: imageSize)
    case .normal, .album, .small, .large:
      // use the bounds size
      break
    @unknown default:
      break
    }

    // adjust for the screen scale
    size = CGSize(width: size.width * scale, height: size.height * scale)

    return size
  }

  func getProfileImageURL(state: ProfilePictureViewState) -> URL? {
    // If there's an existing profile, use that profile's image url handler
    if let profile = Profile.current {
      return profile.imageURL(forMode: pictureMode, size: state.size)
    } else {
      return Profile.imageURL(profileID: state.profileID, pictureMode: pictureMode, size: state.size)
    }
  }

  func setPlaceholderImage() {
    let fillColor = UIColor(red: 157 / 255, green: 177 / 255, blue: 204 / 255, alpha: 1)
    placeholderImageIsValid = true
    hasProfileImage = false

    DispatchQueue.main.async {
      self.imageView.image = _HumanSilhouetteIcon().image(size: self.imageView.bounds.size, color: fillColor)
    }
  }

  func updateImage(data: Data, state: ProfilePictureViewState) {
    guard state == lastState else { return }

    if let image = UIImage(data: data, scale: state.scale) {
      hasProfileImage = true
      DispatchQueue.main.async {
        self.imageView.image = image
      }
    } else {
      hasProfileImage = false
      placeholderImageIsValid = false
      setNeedsImageUpdate()
    }
  }

  func updateImage() {
    needsImageUpdate = false
    if profileID != "me" || AccessToken.isCurrentAccessTokenActive {
      updateImageWithAccessToken()
    } else if Profile.current?.imageURL != nil {
      updateImageWithProfile()
    }
  }
}
