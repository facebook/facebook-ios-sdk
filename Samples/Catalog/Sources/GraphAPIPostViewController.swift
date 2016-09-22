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

import Foundation
import UIKit
import FacebookCore

class GraphAPIPostViewController: UITableViewController {
  func presentAlertControllerFor(_ result: GraphRequestResult<GraphRequest>) {
    let alertController: UIAlertController
    switch result {
    case .success(let response):
      alertController = UIAlertController(title: "Graph Request Success",
                                          message: "Graph Request Succeeded with response: \(response)")
    case .failed(let error):
      alertController = UIAlertController(title: "Graph Request Failed",
                                          message: "Graph Request Failed with error: \(error)")
    }
    present(alertController, animated: true, completion: nil)
  }
}

//--------------------------------------
// MARK: - Post Checkin
//--------------------------------------

extension GraphAPIPostViewController {
  /**
   Posts a check-in to your feed.

   See https://developers.facebook.com/docs/graph-api/reference/user/feed for details.
   Place is hardcoded here, see https://developers.facebook.com/docs/graph-api/using-graph-api/#search for building a place picker.
   */
  @IBAction func postCheckin() {
    let request = GraphRequest(graphPath: "/me/feed",
                               parameters: [ "message" : "Here I am!", "place" : "141887372509674" ],
                               httpMethod: .POST)
    request.start { httpResponse, result in
      switch result {
      case .success(let response):
        print("Graph Request Succeeded: \(response)")
      case .failed(let error):
        print("Graph Request Failed: \(error)")
      }

      self.presentAlertControllerFor(result)
    }
  }
}
