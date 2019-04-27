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
import FBSDKCoreKit

// MARK: -

class GraphAPIReadViewController: UITableViewController {

  func presentAlertController(result: Any?, error: Error?) {
    let alertController: UIAlertController

    switch (result, error) {
    case let (result?, nil):
      print("Graph Request Succeeded: \(result)")
      alertController = UIAlertController(title: "Graph Request Success",
                                          message: "Graph Request Succeeded with result: \(result)")
      present(alertController, animated: true, completion: nil)
    case let (nil, error?):
      print("Graph Request Failed: \(error)")
      alertController = UIAlertController(title: "Graph Request Failed",
                                          message: "Graph Request Failed with error: \(error)")
      present(alertController, animated: true, completion: nil)
    case (_, _):
      print("Graph Request Failed: unknown error")
    }
  }

  //--------------------------------------
  // MARK: - Read Profile
  //--------------------------------------

  /**
   Fetches the currently logged in user's public profile.
   Uses a custom type for profile request.

   See https://developers.facebook.com/docs/graph-api/reference/user/ for details.
   */
  @IBAction private func readProfile() {
    let request = GraphRequest(graphPath: "/me",
                               parameters: ["fields": "id, name"],
                               httpMethod: .get)
    request.start { [weak self] _, result, error in
      self?.presentAlertController(result: result, error: error)
    }
  }

  //--------------------------------------
  // MARK: - Read User Events
  //--------------------------------------

  /**
   Fetches the currently logged in user's list of events.
   */
  @IBAction private func readUserEvents() {
    let request = GraphRequest(graphPath: "/me/events",
                               parameters: [ "fields": "data, description" ],
                               httpMethod: .get)
    request.start { [weak self] _, result, error in
      self?.presentAlertController(result: result, error: error)
    }
  }

  //--------------------------------------
  // MARK: - Read User Friend List
  //--------------------------------------

  /**
   Fetches the currently logged in user's list of facebook friends.
   */
  @IBAction private func readUserFriendList() {
    let request = GraphRequest(graphPath: "/me/friends",
                               parameters: [ "fields": "data" ],
                               httpMethod: .get)
    request.start { [weak self] _, result, error in
      self?.presentAlertController(result: result, error: error)
    }
  }
}
