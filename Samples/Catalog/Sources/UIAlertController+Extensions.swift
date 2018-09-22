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

public extension UIAlertAction {
  /// Action types most commonly used
  enum ActionType {
    ///Ok Option
    case ok
    /// Default Cancel Option
    case cancel
    /// Destructive action with custom title
    case destructive(String)
    /// Custom action with title and style
    case custom(String, UIAlertAction.Style)

    /**
     Creates the action instance for UIAlertController

     - parameter handler: Call Back function
     - returns UIAlertAction Instance
     */
    public func action(handler: ((String) -> Void)? = nil) -> UIAlertAction {
      //Default value
      var actionStyle: UIAlertAction.Style = .default
      var title = ""
      // Action configuration based on the action type
      switch self {

      case .cancel:
        actionStyle = .cancel
        title = "Cancel"

      case .destructive(let optionTitle):
        title = optionTitle
        actionStyle = .destructive

      case let .custom(optionTitle, style):
        title = optionTitle
        actionStyle = style

      default:
        title = "OK"
      }
      //Creating UIAlertAction instance
      return UIAlertAction(title: title, style: actionStyle) { _ in
        if let handler = handler {
          handler(title)
        }
      }

    }
  }
}

extension UIAlertController {
  /**
   Creates the alert view controller using the actions specified, including an "OK" Action

   - parameter title: Title of the alert.
   - parameter message: Alert message body.
   - parameter style: UIAlertControllerStyle enum value
   - parameter handler: Handler block/closure for the clicked option.
   */
  convenience init(title: String,
                   message: String,
                   style: UIAlertController.Style = .alert,
                   handler: ((String) -> Swift.Void)? = nil) {
    //initialize the contoller (self) instance
    self.init(title: title, message: message, preferredStyle: style)

    if actions.isEmpty {
      addAction(UIAlertAction.ActionType.ok.action(handler: handler))
    }
  }
}
