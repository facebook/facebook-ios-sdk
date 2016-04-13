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
  @IBOutlet private weak var imageView: UIImageView?
  @IBOutlet private weak var loginButton: FBSDKDeviceLoginButton?
  @IBOutlet private weak var shareButton: FBSDKDeviceShareButton?

  private var blankImage: UIImage?

  override func viewDidLoad() {
    super.viewDidLoad()

    loginButton?.delegate = self
    blankImage = imageView?.image

    // Subscribe to FB session changes (in case they logged in or out in the second tab)
    NSNotificationCenter.defaultCenter().addObserverForName(
      FBSDKAccessTokenDidChangeNotification,
      object: nil,
      queue: NSOperationQueue.mainQueue()) { (notification) -> Void in
        self.updateContent()
    }

    // If the user is already logged in.
    if FBSDKAccessToken.currentAccessToken() != nil {
      updateContent()
    }

    let linkContent = FBSDKShareLinkContent()
    linkContent.contentURL = NSURL(string: "https://developers.facebook.com/docs/tvos")
    linkContent.contentDescription = "Let's build a tvOS app with Facebook!"
    shareButton?.shareContent = linkContent
  }

  private func flipImageViewToImage(image: UIImage?) {
    guard let imageView = imageView else { return }

    UIView.transitionWithView(imageView,
                              duration: 1,
                              options:.TransitionCrossDissolve,
                              animations: { () -> Void in
                                self.imageView?.image = image
      }, completion: nil)
  }

  private func updateContent() {
    guard let imageView = imageView else {
      return
    }
    guard FBSDKAccessToken.currentAccessToken() != nil else {
      imageView.image = blankImage
      return
    }

    // Download the user's profile image. Usually Facebook Graph API
    // should be accessed via `FBSDKGraphRequest` except for binary data (like the image).
    let urlString = String(
      format: "https://graph.facebook.com/v2.5/me/picture?type=square&width=%d&height=%d&access_token=%@",
      Int(imageView.bounds.size.width),
      Int(imageView.bounds.size.height),
      FBSDKAccessToken.currentAccessToken().tokenString)

    let url = NSURL(string: urlString)
    let userImage = UIImage(data: NSData(contentsOfURL: url!)!)
    flipImageViewToImage(userImage!)
  }
}

extension FirstViewController: FBSDKDeviceLoginButtonDelegate {
  func deviceLoginButtonDidCancel(button: FBSDKDeviceLoginButton) {
    print("Login cancelled")
  }

  func deviceLoginButtonDidLogIn(button: FBSDKDeviceLoginButton) {
    print("Login complete")
    updateContent()
  }

  func deviceLoginButtonDidLogOut(button: FBSDKDeviceLoginButton) {
    print("Logout complete")
    flipImageViewToImage(blankImage)
  }

  func deviceLoginButtonDidFail(button: FBSDKDeviceLoginButton, error: NSError) {
    print("Login error : ", error)
  }
}

extension FirstViewController: FBSDKDeviceShareViewControllerDelegate {
  func deviceShareViewControllerDidComplete(viewController: FBSDKDeviceShareViewController, error: NSError?) {
    print("Device share finished with error?", error)
  }
}

