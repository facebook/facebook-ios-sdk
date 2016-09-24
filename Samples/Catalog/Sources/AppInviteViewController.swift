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

import UIKit

import FacebookShare

final class AppInviteViewController: UITableViewController {
  func showAppInviteDialog(for appInvite: AppInvite) {
    do {
      try AppInvite.Dialog.show(from: self, invite: appInvite) { result in
        switch result {
        case .success(let result):
          print("App Invite Sent with result \(result)")
        case .failed(let error):
          print("Failed to send app invite with error \(error)")
        }
      }
    } catch let error {
      print("Failed to show app invite dialog with error \(error)")
    }
  }
}

extension AppInviteViewController {
  @IBAction func appInviteWithDefaultImage() {
    // Facebook hosted App Link is used here. See https://developers.facebook.com/docs/applinks for details.
    let appInvite = AppInvite(appLink: URL(string: "https://fb.me/1539184863038815")!, deliveryMethod: .facebook)
    showAppInviteDialog(for: appInvite)
  }

  @IBAction func appInviteWithCustomImage() {
    // Facebook hosted App Link is used here. See https://developers.facebook.com/docs/applinks for details.
    let appInvite = AppInvite(appLink: URL(string: "https://fb.me/1539184863038815")!,
                              deliveryMethod: .facebook,
                              previewImageURL: URL(string: "http://catalogapp.parseapp.com/FacebookDeveloper.jpg"))
    showAppInviteDialog(for: appInvite)
  }
}
