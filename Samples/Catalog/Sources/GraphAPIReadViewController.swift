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

class GraphAPIReadViewController: UITableViewController {
  func presentAlertControllerFor(result: GraphRequestResult<GraphRequest>) {
    let alertController: UIAlertController
    switch result {
    case .Success(let response):
      alertController = UIAlertController(title: "Graph Request Success",
                                          message: "Graph Request Succeeded with response: \(response)")
    case .Failed(let error):
      alertController = UIAlertController(title: "Graph Request Failed",
                                          message: "Graph Request Failed with error: \(error)")
    }
    presentViewController(alertController, animated: true, completion: nil)
  }
}

//--------------------------------------
// MARK: - Read Profile
//--------------------------------------

extension GraphAPIReadViewController {
  /**
   Fetches the currently logged in user's public profile.

   See https://developers.facebook.com/docs/graph-api/reference/user/ for details.
   */
  @IBAction func readProfile() {
    let request = GraphRequest(graphPath: "/me",
                               parameters: [ "fields" : "id, name" ],
                               httpMethod: .GET)
    request.start { httpResponse, result in
      switch result {
      case .Success(let response):
        print("Graph Request Succeeded: \(response)")
      case .Failed(let error):
        print("Graph Request Failed: \(error)")
      }

      self.presentAlertControllerFor(result)
    }
  }
}

//--------------------------------------
// MARK: - Read User Events
//--------------------------------------

extension GraphAPIReadViewController {
  /**
   Fetches the currently logged in user's list of events.
   */
  @IBAction func readUserEvents() {
    let request = GraphRequest(graphPath: "/me/events",
                               parameters: [ "fields" : "data, description" ],
                               httpMethod: .GET)
    request.start { _, result in
      switch result {
      case .Success(let response):
        print("Graph Request Succeeded: \(response)")
      case .Failed(let error):
        print("Graph Request Failed: \(error)")
      }

      self.presentAlertControllerFor(result)
    }
  }
}

//--------------------------------------
// MARK: - Read User Friend List
//--------------------------------------

extension GraphAPIReadViewController {
  /**
   Fetches the currently logged in user's list of facebook friends.
   */
  @IBAction func readUserFriendList() {
    let request = GraphRequest(graphPath: "/me/friends",
                               parameters: [ "fields" : "data" ],
                               httpMethod: .GET)
    request.start { httpResponse, result in
      switch result {
      case .Success(let response):
        print("Graph Request Succeeded: \(response)")
      case .Failed(let error):
        print("Graph Request Failed: \(error)")
      }

      self.presentAlertControllerFor(result)
    }
  }
}
