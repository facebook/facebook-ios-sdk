/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import UIKit
import TVMLKit
import FBSDKCoreKit
import FBSDKShareKit
import FBSDKTVOSKit

final class SecondViewController: UIViewController {
  static let kPort = "9002"

  var appController: TVApplicationController?

  override func viewDidLoad() {
    super.viewDidLoad()

    // Subscribe to FB session changes (in case they logged in or out in the first tab)
    // and dispatch similar events to our TVJS. This would not be necessary for pure
    // TVML apps.
    NotificationCenter.default.addObserver(
      forName: .AccessTokenDidChange,
      object: nil,
      queue: OperationQueue.main) { notification in
        let event = ((notification as NSNotification).userInfo![AccessTokenChangeNewKey] != nil) ? "customOnFacebookLogin" : "customOnFacebookLogout"
        self.appController?.evaluate(inJavaScriptContext: { context -> Void in
          context.evaluateScript("navigationDocument.documents[0].dispatchEvent(new CustomEvent('\(event)'))")
          }, completion: nil)
    }

    // Connect the FBSDK to get TVML extensions
    TVInterfaceFactory.shared().extendedInterfaceCreator = TVInterfaceFactory(interfaceCreator: nil)

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
    navigationController?.addChild(appController.navigationController)
    navigationController?.view.addSubview(appController.navigationController.view)
    appController.navigationController.didMove(toParent: navigationController)
  }

  func appController(_ appController: TVApplicationController, evaluateAppJavaScriptIn jsContext: JSContext) {
    // Add the TVML/TVJS extensions for FBSDK
    jsContext.setObject(FBSDKTVOSKit.JS.self, forKeyedSubscript: "FBSDKJS" as (NSCopying & NSObjectProtocol))

    // Define a custom _shareLink helper
    let shareLink: @convention(block) () -> Void = {
      let content = ShareLinkContent()
      content.contentURL = URL(string: "http://www.apple.com/tv/")!
      ShareAPI(content: content, delegate: self).share()
    }
    jsContext.setObject(unsafeBitCast(shareLink, to: AnyObject.self), forKeyedSubscript: "_shareLink" as (NSCopying & NSObjectProtocol))
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

extension SecondViewController: SharingDelegate {

  func sharer(_ sharer: Sharing, didCompleteWithResults results: [String : Any]) {
    appController!.evaluate(inJavaScriptContext: { (context) -> Void in
      context.evaluateScript("shareLinkCallback()")
    }, completion: nil)
  }

  public func sharer(_ sharer: Sharing, didFailWithError error: Error) {
    print("Share failed %@", error)
  }

  func sharerDidCancel(_ sharer: Sharing) {
    print("Share cancelled")
  }
}
