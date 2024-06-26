// (c) Meta Platforms, Inc. and affiliates. Confidential and proprietary.

import SafariServices
import UIKit
import WebKit

class TestWebViewController: UIViewController {

  @IBOutlet var urlField: UITextField!
  @IBOutlet var wkWebView: WKWebView!
  @IBOutlet var uiWebView: UIWebView!
  let urlPrefix = "https://"
  override func viewDidLoad() {
    super.viewDidLoad()
  }

  @IBAction func wkWebViewControllerPressed(_sender: Any) {
    let url = urlPrefix + urlField.text!
    let urlRequest = URLRequest(url: URL(string: url)!)
    wkWebView.load(urlRequest)
  }

  @IBAction func safariViewControllerPressed(_ sender: Any) {
    let url = urlPrefix + urlField.text!
    let svc = SFSafariViewController(url: URL(string: url)!)
    present(svc, animated: true) {
      // do nothing.
    }
  }

  @IBAction func uiWebViewControllerPressed(_ sender: Any) {
    let url = urlPrefix + urlField.text!
    let urlRequest = URLRequest(url: URL(string: url)!)
    uiWebView.loadRequest(urlRequest)
  }
}
