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

@testable import FacebookCore

import FBSDKShareKit

extension AppInvite {
  internal class SDKDelegate: NSObject, FBSDKAppInviteDialogDelegate {
    internal var completion: ((Result) -> Void)?

    func setupAsDelegateFor(_ dialog: FBSDKAppInviteDialog) {
      // We need for the connection to retain us,
      // so we can stick around and keep calling into handlers,
      // as long as the connection is alive/sending messages.
      objc_setAssociatedObject(dialog, Unmanaged.passUnretained(self).toOpaque(), self, .OBJC_ASSOCIATION_RETAIN)
      dialog.delegate = self
    }

    func appInviteDialog(_ appInviteDialog: FBSDKAppInviteDialog?,
                         didCompleteWithResults results: [AnyHashable: Any]?) {
      completion?(.success(results?.keyValueFlatMap { ($0 as? String, $1 as? String) } ?? [:]))
    }

    func appInviteDialog(_ appInviteDialog: FBSDKAppInviteDialog?, didFailWithError error: Error) {
      completion?(.failed(error))
    }
  }
}
