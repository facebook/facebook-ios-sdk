// Copyright (c) 2014-present, Facebook, Inc. All rights reserved.
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

@objcMembers
class TestNotificationCenter: NSObject, NotificationObserving, NotificationPosting {

  struct ObserverEvidence: Equatable {
    let observer: Any
    let name: Notification.Name?
    let selector: Selector
    let object: Any?

    static func == (
      lhs: TestNotificationCenter.ObserverEvidence,
      rhs: TestNotificationCenter.ObserverEvidence
    ) -> Bool {
      lhs.observer as AnyObject === rhs.observer as AnyObject &&
        lhs.name == rhs.name &&
        lhs.selector == rhs.selector &&
        lhs.object as AnyObject === rhs.object as AnyObject
    }
  }

  var capturedRemovedObservers = [Any]()
  var capturedPostNames = [NSNotification.Name]()
  var capturedPostObjects = [Any]()
  var capturedPostUserInfos = [[AnyHashable: Any]]()

  var capturedAddObserverInvocations = [ObserverEvidence]()

  // MARK: Posting

  func post(
    name: Notification.Name,
    object: Any?,
    userInfo: [AnyHashable: Any]? = nil
  ) {
    self.capturedPostNames.append(name)
    self.capturedPostObjects.append(object as Any)
    self.capturedPostUserInfos.append(userInfo ?? [:])
  }

  // MARK: Observing
  func removeObserver(_ observer: Any) {
    capturedRemovedObservers.append(observer)
  }

  func addObserver(
    _ observer: Any,
    selector: Selector,
    name: Notification.Name?,
    object: Any?
  ) {
    capturedAddObserverInvocations.append(
      ObserverEvidence(
        observer: observer,
        name: name,
        selector: selector,
        object: object
      )
    )
  }

  func clearTestEvidence() {
    capturedRemovedObservers = []
    capturedPostNames = []
    capturedPostObjects = []
    capturedPostUserInfos = []
  }
}
