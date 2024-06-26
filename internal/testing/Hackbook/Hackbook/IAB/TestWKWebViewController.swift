// (c) Meta Platforms, Inc. and affiliates. Confidential and proprietary.

import UIKit
import WebKit

class TestWKWebViewController: UIViewController {

  @IBOutlet var urlField: UITextField!
  @IBOutlet var wkWebView: WKWebView!
  let urlPrefix = "https://"
  override func viewDidLoad() {
    super.viewDidLoad()
  }

  @IBAction func wkWebViewPressed(_sender: Any) {
    let url = urlPrefix + urlField.text!
    let urlRequest = URLRequest(url: URL(string: url)!)
    wkWebView.load(urlRequest)
  }
}
