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
    NSNotificationCenter.defaultCenter().addObserverForName(
      FBSDKAccessTokenDidChangeNotification,
      object: nil,
      queue: NSOperationQueue.mainQueue()) { notification -> Void in
        let event = (notification.userInfo![FBSDKAccessTokenChangeNewKey] != nil) ? "onFacebookLogin" : "onFacebookLogout"
        self.appController?.evaluateInJavaScriptContext({ context -> Void in
          context.evaluateScript("navigationDocument.documents[0].dispatchEvent(new CustomEvent('\(event)'))")
          }, completion: nil)
    }

    // Connect the FBSDK to get TVML extensions
    TVInterfaceFactory.sharedInterfaceFactory().extendedInterfaceCreator = FBSDKTVInterfaceFactory()

    // Make sure you start a webserver that can serve the 'client' directory.
    // For example, run `python -m SimpleHTTPServer 9002` from the 'client' directory.
    // Note for this sample, App Transport Security has been set to Allow Arbitrary Loads.
    let javascriptURL = NSURL(string: "http://localhost:\(SecondViewController.kPort)/main.js")
    let appControllerContext = TVApplicationControllerContext()
    appControllerContext.javaScriptApplicationURL = javascriptURL!
    appController = TVApplicationController(context: appControllerContext, window: nil, delegate: self)
  }
}
extension SecondViewController: TVApplicationControllerDelegate {

  func appController(appController: TVApplicationController, didFinishLaunchingWithOptions options: [String: AnyObject]?) {
    // TVJS loaded, add its navigation controller to our heirarchy.
    navigationController?.addChildViewController(appController.navigationController)
    navigationController?.view.addSubview(appController.navigationController.view)
    appController.navigationController.didMoveToParentViewController(navigationController)
  }

  func appController(appController: TVApplicationController, evaluateAppJavaScriptInContext jsContext: JSContext) {
    // Add the TVML/TVJS extensions for FBSDK
    jsContext.setObject(FBSDKJS.self, forKeyedSubscript: "FBSDKJS")

    // Define a custom _shareLink helper
    let shareLink: @convention(block) Void -> Void = {
      let content = FBSDKShareLinkContent()
      content.contentURL = NSURL(string: "http://www.apple.com/tv/")!
      FBSDKShareAPI.shareWithContent(content, delegate: self)
    }
    jsContext.setObject(unsafeBitCast(shareLink, AnyObject.self), forKeyedSubscript: "_shareLink")
  }

  func appController(appController: TVApplicationController, didFailWithError error: NSError) {
    let title = "TVML Error"
    let message = error.code == TVMLKitError.FailedToLaunch.rawValue ?
      "Did you start the web server in the 'client' directory on port \(SecondViewController.kPort)? " +
      "You can run 'python -m SimpleHTTPServer \(SecondViewController.kPort)' from the 'client' directory."
      : error.localizedDescription
    let alertController = UIAlertController(title: title, message: message, preferredStyle:.Alert)
    navigationController?.presentViewController(alertController, animated: true, completion: nil)
  }
}

extension SecondViewController: FBSDKSharingDelegate {

  func sharer(sharer: FBSDKSharing!, didCompleteWithResults results: [NSObject : AnyObject]!) {
    appController!.evaluateInJavaScriptContext({ (context) -> Void in
      context.evaluateScript("shareLinkCallback()")
      }, completion: nil)
  }

  func sharer(sharer: FBSDKSharing!, didFailWithError error: NSError!) {
    print("Share failed %@", error)
  }

  func sharerDidCancel(sharer: FBSDKSharing!) {
    print("Share cancelled")
  }
}
