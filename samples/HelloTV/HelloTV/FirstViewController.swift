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

class FirstViewController: UIViewController,
  FBSDKDeviceLoginButtonDelegate,
  FBSDKSharingDelegate,
  FBSDKDeviceLoginViewControllerDelegate
{
  @IBOutlet weak var imageView: UIImageView!
  @IBOutlet weak var loginButton: FBSDKDeviceLoginButton!
  var _blankImage: UIImage!

  override func viewDidLoad() {
    super.viewDidLoad()
    loginButton.delegate = self
    _blankImage = self.imageView.image

    // Subscribe to FB session changes (in case they logged in or out in the second tab)
    NSNotificationCenter.defaultCenter().addObserverForName(
      FBSDKAccessTokenDidChangeNotification,
      object: nil,
      queue: NSOperationQueue.mainQueue()) { (notification) -> Void in
        self._updateContent()
    }

    // If the user is already logged in.
    if (FBSDKAccessToken.currentAccessToken() != nil) {
      _updateContent()
    }
  }

  @IBAction func shareLinkTap(sender: AnyObject) {
    // Check for publish permissions; otherwise, ask for them.
    if (FBSDKAccessToken.currentAccessToken()?.hasGranted("publish_actions") != nil) {
      _publishLink()
    } else {
      let alertController = UIAlertController(
        title: "Grant Permissions?",
        message: "In order to share the link, can we post on your behalf on Facebook?",
        preferredStyle: .Alert)
      alertController.addAction(UIAlertAction(
        title: "Yes",
        style: .Default,
        handler: { (UIAlertAction) -> Void in
          let askPublishViewController = FBSDKDeviceLoginViewController()
          askPublishViewController.publishPermissions = ["publish_actions"]
          askPublishViewController.delegate = self
          self.showViewController(askPublishViewController, sender: self)
      }))
      alertController.addAction(UIAlertAction(
        title: "No Thanks",
        style: .Cancel,
        handler: nil))
      self.showViewController(alertController, sender: self)
    }
  }

  func _flipImageViewToImage(image: UIImage) {
    UIView.transitionWithView(self.imageView,
      duration: 1,
      options:.TransitionCrossDissolve,
      animations: { () -> Void in
        self.imageView.image = image
      }, completion: nil)
  }

  func _publishLink() {
    let linkContent = FBSDKShareLinkContent()
    linkContent.contentURL = NSURL(string: "https://developers.facebook.com/docs/tvos")
    linkContent.contentDescription = "Let's build a tvOS app with Facebook!"
    FBSDKShareAPI.shareWithContent(linkContent, delegate: self)
  }

  func _updateContent() {
    if (self.imageView.image == _blankImage) {
      // Download the user's profile image. Usually Facebook Graph API
      // should be accessed via `FBSDKGraphRequest` except for binary data (like the image).
      let urlString = String(
        format: "https://graph.facebook.com/v2.5/me/picture?type=square&width=%d&height=%d&access_token=%@",
        Int(self.imageView.bounds.size.width),
        Int(self.imageView.bounds.size.height),
        FBSDKAccessToken.currentAccessToken().tokenString)

      let url = NSURL(string: urlString)
      let userImage = UIImage(data: NSData(contentsOfURL: url!)!)
      _flipImageViewToImage(userImage!)
    }
  }

  //MARK: FBSDKSharingDelegate

  func sharer(sharer: FBSDKSharing!, didCompleteWithResults results: [NSObject : AnyObject]!) {
    let alert = UIAlertController(
      title: "Success!",
      message: "Thanks for sharing!",
      preferredStyle: .Alert)
    alert .addAction(UIAlertAction(
      title: "OK",
      style: .Default,
      handler: nil))
    self.showViewController(alert, sender: self)
  }

  func sharer(sharer: FBSDKSharing!, didFailWithError error: NSError!) {
    print("Share failed %@", error)
  }
  func sharerDidCancel(sharer: FBSDKSharing!) {
    print("Share cancelled")
  }

  //MARK: FBSDKDeviceLoginButtonDelegate

  func deviceLoginButtonDidCancel(button: FBSDKDeviceLoginButton) {
    print("Login cancelled");
  }

  func deviceLoginButtonDidLogIn(button: FBSDKDeviceLoginButton) {
    print("Login complete");
    _updateContent()
  }

  func deviceLoginButtonDidLogOut(button: FBSDKDeviceLoginButton) {
    print("Logout complete");
    _flipImageViewToImage(_blankImage);
  }

  func deviceLoginButtonDidFail(button: FBSDKDeviceLoginButton, error: NSError) {
    print("Login error : %@", error)
  }

  //MARK: FBSDKDeviceLoginViewControllerDelegate

  func deviceLoginViewControllerDidCancel(viewController: FBSDKDeviceLoginViewController) {
    print("Cancelled publish permissions request");
  }

  func deviceLoginViewControllerDidFinish(viewController: FBSDKDeviceLoginViewController) {
    _publishLink()
    _updateContent()
  }

  func deviceLoginViewControllerDidFail(viewController: FBSDKDeviceLoginViewController, error: NSError) {
    print ("Publish permissions request error: ", error)
  }
}

