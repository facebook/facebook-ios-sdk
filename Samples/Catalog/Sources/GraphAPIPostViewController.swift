// Copyright (c) 2016-present, Facebook, Inc. All rights reserved.
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

import FacebookCore
import FBSDKCoreKit
import Foundation
import UIKit

class GraphAPIPostViewController: UITableViewController {

  //--------------------------------------
  // MARK: - Post Checkin
  //--------------------------------------

  /**
   Posts a check-in to your feed.

   See https://developers.facebook.com/docs/graph-api/reference/user/feed for details.
   Place is hardcoded here, see https://developers.facebook.com/docs/graph-api/using-graph-api/#search
   for building a place picker.
   */
  @IBAction private func postCheckin() {
    let request = GraphRequest(graphPath: "/me/feed",
                               parameters: [ "message": "Here I am!", "place": "141887372509674" ],
                               httpMethod: .post)
    request.start { [weak self] _, result, error in

      let alertController: UIAlertController

      switch (result, error) {
      case let (result?, nil):
        print("Graph Request Succeeded: \(result)")
        alertController = UIAlertController(title: "Graph Request Success",
                                            message: "Graph Request Succeeded with result: \(result)")
        self?.present(alertController, animated: true, completion: nil)
      case let (nil, error?):
        print("Graph Request Failed: \(error)")
        alertController = UIAlertController(title: "Graph Request Failed",
                                            message: "Graph Request Failed with error: \(error)")
        self?.present(alertController, animated: true, completion: nil)
      case (_, _):
        print("Graph Request Failed: unknown error")
      }
    }
  }
}
