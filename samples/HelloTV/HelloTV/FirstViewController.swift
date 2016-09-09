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

import UIKit
import FBSDKShareKit
import FBSDKTVOSKit

class FirstViewController: UIViewController {
  @IBOutlet fileprivate weak var imageView: UIImageView?
  @IBOutlet fileprivate weak var loginButton: FBSDKDeviceLoginButton?
  @IBOutlet fileprivate weak var shareButton: FBSDKDeviceShareButton?

  fileprivate var blankImage: UIImage?

  override func viewDidLoad() {
    super.viewDidLoad()

    loginButton?.delegate = self
    blankImage = imageView?.image

    // Subscribe to FB session changes (in case they logged in or out in the second tab)
    NotificationCenter.default.addObserver(
      forName: .FBSDKAccessTokenDidChange,
      object: nil,
      queue: .main) { (notification) -> Void in
        self.updateContent()
    }

    // If the user is already logged in.
    if FBSDKAccessToken.current() != nil {
      updateContent()
    }

    let linkContent = FBSDKShareLinkContent()
    linkContent.contentURL = URL(string: "https://developers.facebook.com/docs/tvos")
    linkContent.contentDescription = "Let's build a tvOS app with Facebook!"
    shareButton?.shareContent = linkContent
  }

  fileprivate func flipImageViewToImage(_ image: UIImage?) {
    guard let imageView = imageView else { return }

    UIView.transition(with: imageView,
                      duration: 1,
                      options:.transitionCrossDissolve,
                      animations: { () -> Void in
                        self.imageView?.image = image
      }, completion: nil)
  }

  fileprivate func updateContent() {
    guard let imageView = imageView else {
      return
    }
    guard FBSDKAccessToken.current() != nil else {
      imageView.image = blankImage
      return
    }

    // Download the user's profile image. Usually Facebook Graph API
    // should be accessed via `FBSDKGraphRequest` except for binary data (like the image).
    let urlString = String(
      format: "https://graph.facebook.com/v2.5/me/picture?type=square&width=%d&height=%d&access_token=%@",
      Int(imageView.bounds.size.width),
      Int(imageView.bounds.size.height),
      FBSDKAccessToken.current().tokenString)

    let url = URL(string: urlString)
    let userImage = UIImage(data: try! Data(contentsOf: url!))
    flipImageViewToImage(userImage!)
  }
}

extension FirstViewController: FBSDKDeviceLoginButtonDelegate {
  func deviceLoginButtonDidCancel(_ button: FBSDKDeviceLoginButton) {
    print("Login cancelled")
  }

  func deviceLoginButtonDidLog(in button: FBSDKDeviceLoginButton) {
    print("Login complete")
    updateContent()
  }

  func deviceLoginButtonDidLogOut(_ button: FBSDKDeviceLoginButton) {
    print("Logout complete")
    flipImageViewToImage(blankImage)
  }

  public func deviceLoginButtonDidFail(_ button: FBSDKDeviceLoginButton, error: Error) {
    print("Login error : ", error)
  }
}

extension FirstViewController: FBSDKDeviceShareViewControllerDelegate {

  public func deviceShareViewControllerDidComplete(_ viewController: FBSDKDeviceShareViewController, error: Error?) {
    print("Device share finished with error?", error)
  }
}

