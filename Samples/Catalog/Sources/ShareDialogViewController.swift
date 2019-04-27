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

import MobileCoreServices
import UIKit

import FacebookShare
import FBSDKShareKit

final class ShareDialogViewController: UITableViewController,
  UIImagePickerControllerDelegate,
  UINavigationControllerDelegate,
SharingDelegate {

  func showShareDialog<C: SharingContent>(_ content: C, mode: ShareDialog.Mode = .automatic) {
    let dialog = ShareDialog(fromViewController: self, content: content, delegate: self)
    dialog.mode = mode
    dialog.show()
  }

  //--------------------------------------
  // MARK: - Link Content
  //--------------------------------------

  @IBAction private func showLinkShareDialogModeAutomatic() {
    guard let url = URL(string: "https://newsroom.fb.com/") else { return }
    let content = ShareLinkContent()
    content.contentURL = url

    // placeId is hardcoded here, see https://developers.facebook.com/docs/graph-api/using-graph-api/#search
    // for building a place picker.
    content.placeID = "166793820034304"

    showShareDialog(content, mode: .automatic)
  }

  @IBAction private func showLinkShareDialogModeWeb() {
    guard let url = URL(string: "https://newsroom.fb.com/") else { return }
    let content = ShareLinkContent()
    content.contentURL = url

    // placeId is hardcoded here, see https://developers.facebook.com/docs/graph-api/using-graph-api/#search
    // for building a place picker.
    content.placeID = "166793820034304"

    showShareDialog(content, mode: .web)
  }

  //--------------------------------------
  // MARK: - Photo Content
  //--------------------------------------

  @IBAction private func showShareDialogPhotoContent() {
    let content = SharePhotoContent()
    content.photos = [SharePhoto(image: #imageLiteral(resourceName: "sky"), userGenerated: true)]
    showShareDialog(content)
  }

  //--------------------------------------
  // MARK: - Video Content
  //--------------------------------------

  @IBAction private func showShareDialogVideoContent() {
    let imagePickerController = UIImagePickerController()
    imagePickerController.delegate = self
    imagePickerController.sourceType = .photoLibrary
    imagePickerController.mediaTypes = [kUTTypeMovie as String]
    present(imagePickerController, animated: true, completion: nil)
  }

  // MARK: UIImagePickerControllerDelegate

  func imagePickerController(_ picker: UIImagePickerController,
                             didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
    picker.dismiss(animated: true, completion: nil)

    guard let videoURL = info[.referenceURL] as? URL else {
      return
    }

    let content = ShareVideoContent()
    content.video = ShareVideo(videoURL: videoURL)
    showShareDialog(content)
  }

  func sharer(_ sharer: Sharing, didCompleteWithResults results: [String: Any]) {
    let title = "Share Success"
    let message = "Succesfully shared: \(results)"
    let alertController = UIAlertController(title: title, message: message)
    self.present(alertController, animated: true, completion: nil)
  }

  func sharer(_ sharer: Sharing, didFailWithError error: Error) {
    let title = "Share Failed"
    let message = "Sharing failed with error \(error)"
    let alertController = UIAlertController(title: title, message: message)
    self.present(alertController, animated: true, completion: nil)
  }

  func sharerDidCancel(_ sharer: Sharing) {
    let title = "Share Cancelled"
    let message = "Sharing was cancelled by user."
    let alertController = UIAlertController(title: title, message: message)
    self.present(alertController, animated: true, completion: nil)
  }
}
