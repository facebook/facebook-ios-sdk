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
    } catch {
      print("Failed to show app invite dialog with error \(error)")
    }
  }

  @IBAction private func appInviteWithDefaultImage() {
    // Facebook hosted App Link is used here. See https://developers.facebook.com/docs/applinks for details.
    guard let appLink = URL(string: "https://fb.me/1539184863038815") else { return }
    let appInvite = AppInvite(appLink: appLink, deliveryMethod: .facebook)
    showAppInviteDialog(for: appInvite)
  }

  @IBAction private func appInviteWithCustomImage() {
    // Facebook hosted App Link is used here. See https://developers.facebook.com/docs/applinks for details.
    guard let appLink = URL(string: "https://fb.me/1539184863038815") else { return }
    let previewImageURL = URL(string: "http://catalogapp.parseapp.com/FacebookDeveloper.jpg")
    let appInvite = AppInvite(appLink: appLink, deliveryMethod: .facebook, previewImageURL: previewImageURL)
    showAppInviteDialog(for: appInvite)
  }
}
