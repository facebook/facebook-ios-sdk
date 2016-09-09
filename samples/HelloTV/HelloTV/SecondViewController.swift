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
import TVMLKit
import FBSDKCoreKit
import FBSDKShareKit
import FBSDKTVOSKit

class SecondViewController: UIViewController {
  static let kPort = "9002"

  var appController: TVApplicationController?

  override func viewDidLoad() {
    super.viewDidLoad()

    // Subscribe to FB session changes (in case they logged in or out in the first tab)
    // and dispatch similar events to our TVJS. This would not be necessary for pure
    // TVML apps.
    NotificationCenter.default.addObserver(
      forName: NSNotification.Name.FBSDKAccessTokenDidChange,
      object: nil,
      queue: OperationQueue.main) { notification -> Void in
        let event = ((notification as NSNotification).userInfo![FBSDKAccessTokenChangeNewKey] != nil) ? "customOnFacebookLogin" : "customOnFacebookLogout"
        self.appController?.evaluate(inJavaScriptContext: { context -> Void in
          context.evaluateScript("navigationDocument.documents[0].dispatchEvent(new CustomEvent('\(event)'))")
          }, completion: nil)
    }

    // Connect the FBSDK to get TVML extensions
    TVInterfaceFactory.shared().extendedInterfaceCreator = FBSDKTVInterfaceFactory()

    // Make sure you start a webserver that can serve the 'client' directory.
    // For example, run `python -m SimpleHTTPServer 9002` from the 'client' directory.
    // Note for this sample, App Transport Security has been set to Allow Arbitrary Loads.
    let javascriptURL = URL(string: "http://localhost:\(SecondViewController.kPort)/main.js")
    let appControllerContext = TVApplicationControllerContext()
    appControllerContext.javaScriptApplicationURL = javascriptURL!
    appController = TVApplicationController(context: appControllerContext, window: nil, delegate: self)
  }
}
extension SecondViewController: TVApplicationControllerDelegate {

  func appController(_ appController: TVApplicationController, didFinishLaunching options: [String: Any]?) {
    // TVJS loaded, add its navigation controller to our heirarchy.
    navigationController?.addChildViewController(appController.navigationController)
    navigationController?.view.addSubview(appController.navigationController.view)
    appController.navigationController.didMove(toParentViewController: navigationController)
  }

  func appController(_ appController: TVApplicationController, evaluateAppJavaScriptIn jsContext: JSContext) {
    // Add the TVML/TVJS extensions for FBSDK
    jsContext.setObject(FBSDKJS.self, forKeyedSubscript: "FBSDKJS" as (NSCopying & NSObjectProtocol)!)

    // Define a custom _shareLink helper
    let shareLink: @convention(block) (Void) -> Void = {
      let content = FBSDKShareLinkContent()
      content.contentURL = URL(string: "http://www.apple.com/tv/")!
      FBSDKShareAPI.share(with: content, delegate: self)
    }
    jsContext.setObject(unsafeBitCast(shareLink, to: AnyObject.self), forKeyedSubscript: "_shareLink" as (NSCopying & NSObjectProtocol)!)
  }

  func appController(_ appController: TVApplicationController, didFail error: Error) {
    let title = "TVML Error"
    let nserror = error as NSError
    let message =
      (nserror.code == TVMLKitError.failedToLaunch.rawValue ?
        "Did you start the web server in the 'client' directory on port \(SecondViewController.kPort)? " +
        "You can run 'python -m SimpleHTTPServer \(SecondViewController.kPort)' from the 'client' directory."
        : error.localizedDescription )

    let alertController = UIAlertController(title: title, message: message, preferredStyle:.alert)
    navigationController?.present(alertController, animated: true, completion: nil)
  }
}

extension SecondViewController: FBSDKSharingDelegate {

  func sharer(_ sharer: FBSDKSharing!, didCompleteWithResults results: [AnyHashable: Any]!) {
    appController!.evaluate(inJavaScriptContext: { (context) -> Void in
      context.evaluateScript("shareLinkCallback()")
      }, completion: nil)
  }

  public func sharer(_ sharer: FBSDKSharing!, didFailWithError error: Error!) {
    print("Share failed %@", error)
  }

  func sharerDidCancel(_ sharer: FBSDKSharing!) {
    print("Share cancelled")
  }
}
