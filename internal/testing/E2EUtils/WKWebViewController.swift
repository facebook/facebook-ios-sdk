// (c) Meta Platforms, Inc. and affiliates. Confidential and proprietary.

import UIKit
import WebKit

typealias SessionCompletionHandler = @convention(block) (URL?, NSError?) -> Void

class WKWebViewController: UIViewController, WKNavigationDelegate, WKUIDelegate {

  lazy var webView: WKWebView = {
    let webConfiguration = WKWebViewConfiguration()
    if #available(iOS 11.0, *), self.callbackScheme != nil {
      webConfiguration.setURLSchemeHandler(CustomSchemeHandler(viewController: self), forURLScheme: self.callbackScheme!)
    }
    webConfiguration.applicationNameForUserAgent = self.userAgent ?? "JestE2E"
    let view = WKWebView(
      frame: .zero,
      configuration: webConfiguration
    )
    view.uiDelegate = self
    view.navigationDelegate = self
    return view
  }()

  var url: URL?
  var userAgent: String?
  public var callbackScheme: String?

  init(url: URL, callbackScheme: String, userAgent: String?) {
    self.url = url
    self.callbackScheme = callbackScheme
    self.userAgent = userAgent
    super.init(nibName: nil, bundle: nil)
  }

  required init?(coder decoder: NSCoder) {
    super.init(coder: decoder)
  }

  public override func loadView() {
    super.loadView()
    view = webView
  }

  public override func viewDidLoad() {
    super.viewDidLoad()
    guard let requestUrl = url else { return }
    webView.load(URLRequest(url: requestUrl))
  }

  func webView(
    _ webView: WKWebView,
    didReceive challenge: URLAuthenticationChallenge,
    completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
  ) {
    guard let serverTrust = challenge.protectionSpace.serverTrust
    else {
      return completionHandler(.useCredential, nil)
    }
    completionHandler(.useCredential, URLCredential(trust: serverTrust))
  }
}

@available(iOS 11.0, *)
class CustomSchemeHandler: NSObject, WKURLSchemeHandler {

  var viewController: WKWebViewController

  init(viewController: WKWebViewController) {
    self.viewController = viewController
  }

  @available(iOS 11.0, *)
  func webView(_ webView: WKWebView, start urlSchemeTask: WKURLSchemeTask) {
    DispatchQueue.main.async {
      guard let url = urlSchemeTask.request.url, let callbackScheme = self.viewController.callbackScheme, url.scheme == callbackScheme,
            let cls = NSClassFromString("FBSDKBridgeAPI") as? NSObject.Type,
            let sharedInstance = cls.perform(NSSelectorFromString("sharedInstance"))?.takeUnretainedValue() as? NSObject,
            let completionBlock = sharedInstance.value(forKey: "_authenticationSessionCompletionHandler")
      else {
        return self.viewController.dismiss(animated: false, completion: nil)
      }
      let handler = unsafeBitCast(completionBlock as AnyObject, to: SessionCompletionHandler.self)
      handler(url, nil)
      self.viewController.dismiss(animated: false, completion: nil)
    }
  }

  @available(iOS 11.0, *)
  func webView(_ webView: WKWebView, stop urlSchemeTask: WKURLSchemeTask) {
    print("Task was stopped")
  }
}
