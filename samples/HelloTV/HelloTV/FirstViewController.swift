/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import UIKit
import FBSDKShareKit
import FBSDKTVOSKit

class FirstViewController: UIViewController {
  @IBOutlet fileprivate weak var imageView: UIImageView?
  @IBOutlet fileprivate weak var loginButton: FBDeviceLoginButton?
  @IBOutlet fileprivate weak var shareButton: FBDeviceShareButton?

  fileprivate var blankImage: UIImage?

  override func viewDidLoad() {
    super.viewDidLoad()

    loginButton?.delegate = self
    blankImage = imageView?.image

    // Subscribe to FB session changes (in case they logged in or out in the second tab)
    NotificationCenter.default.addObserver(
      forName: .AccessTokenDidChange,
      object: nil,
      queue: .main) { (notification) -> Void in
        self.updateContent()
    }

    // If the user is already logged in.
    if AccessToken.current != nil {
      updateContent()
    }

    let linkContent = ShareLinkContent()
    linkContent.contentURL = URL(string: "https://developers.facebook.com/docs/tvos")!
    shareButton?.shareContent = linkContent
  }

  fileprivate func flipImageViewToImage(_ image: UIImage?) {
    guard let imageView = imageView else { return }

    UIView.transition(with: imageView,
                      duration: 1,
                      options:.transitionCrossDissolve,
                      animations: {
                        self.imageView?.image = image
    }, completion: nil)
  }

  fileprivate func updateContent() {
    guard let imageView = imageView else {
      return
    }
    guard AccessToken.current != nil else {
      imageView.image = blankImage
      return
    }

    // Download the user's profile image. Usually Facebook Graph API
    // should be accessed via `FBSDKGraphRequest` except for binary data (like the image).
    let urlString = String(
      format: "https://graph.facebook.com/v2.5/me/picture?type=square&width=%d&height=%d&access_token=%@",
      Int(imageView.bounds.size.width),
      Int(imageView.bounds.size.height),
      AccessToken.current?.tokenString ?? "")

    guard let url = URL(string: urlString) else {
      print("Invalid URL")
      return
    }

    guard let data = try? Data(contentsOf: url) else {
      print("Failed to download with the URL")
      return
    }

    guard let userImage = UIImage(data: data) else {
      print("Failed to load the downloaded data as image")
      return
    }

    flipImageViewToImage(userImage)
  }
}

extension FirstViewController: DeviceLoginButtonDelegate {

  func deviceLoginButtonDidCancel(_ button: FBDeviceLoginButton) {
    print("Login cancelled")
  }

  func deviceLoginButtonDidLogIn(_ button: FBDeviceLoginButton) {
    print("Login complete")
    updateContent()
  }

  func deviceLoginButtonDidLogOut(_ button: FBDeviceLoginButton) {
    print("Logout complete")
    flipImageViewToImage(blankImage)
  }

  func deviceLoginButton(_ button: FBDeviceLoginButton, didFailWithError error: Error) {
    print("Login error : ", error)
  }
}

extension FirstViewController: DeviceShareViewControllerDelegate {

  public func deviceShareViewControllerDidComplete(_ viewController: FBDeviceShareViewController, error: Error?) {
    print("Device share finished with error?", error as Any)
  }
}
