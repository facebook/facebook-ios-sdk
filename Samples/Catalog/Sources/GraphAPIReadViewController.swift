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

  func presentAlertControllerFor<P: GraphRequestProtocol>(_ result: GraphRequestResult<P>) {
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
// MARK: - Read Profile
//--------------------------------------

struct FBProfileRequest: GraphRequestProtocol {
  typealias Response = GraphResponse

  var graphPath = "/me"
  var parameters: [String : Any]? = ["fields": "id, name" as AnyObject]
  var accessToken = AccessToken.current
  var httpMethod: GraphRequestHTTPMethod = .GET
  var apiVersion: GraphAPIVersion = 2.7
}

extension GraphAPIReadViewController {
  /**
   Fetches the currently logged in user's public profile.
   Uses a custom type for profile request.

   See https://developers.facebook.com/docs/graph-api/reference/user/ for details.
   */
  @IBAction func readProfile() {
    let request = FBProfileRequest()
    request.start { (httpResponse, result) in
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
      case .success(let response):
        print("Graph Request Succeeded: \(response)")
      case .failed(let error):
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
      case .success(let response):
        print("Graph Request Succeeded: \(response)")
      case .failed(let error):
        print("Graph Request Failed: \(error)")
      }

      self.presentAlertControllerFor(result)
    }
  }
}
