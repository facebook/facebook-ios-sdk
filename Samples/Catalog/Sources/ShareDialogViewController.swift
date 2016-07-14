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
import MobileCoreServices

import FacebookShare

final class ShareDialogViewController: UITableViewController {

  func showShareDialog<C: ContentProtocol>(content: C, mode: ShareDialogMode = .Automatic) {
    let dialog = ShareDialog(content: content)
    dialog.presentingViewController = self
    dialog.mode = mode
    do {
      try dialog.show()
    } catch (let error) {
      let alertController = UIAlertController(title: "Invalid share content", message: "Failed to present share dialog with error \(error)")
      presentViewController(alertController, animated: true, completion: nil)
    }
  }
}

//--------------------------------------
// MARK: - Link Content
//--------------------------------------

extension ShareDialogViewController {
  @IBAction func showLinkShareDialogModeAutomatic() {
    var content = LinkShareContent(url: NSURL(string: "https://newsroom.fb.com/")!,
                                   title: "Name: Facebook News Room",
                                   description: "Description: The Facebook Swift SDK helps you develop Facebook integrated iOS apps.",
                                   imageURL: NSURL(string: "https://raw.github.com/fbsamples/ios-3.x-howtos/master/Images/iossdk_logo.png"))

    // placeId is hardcoded here, see https://developers.facebook.com/docs/graph-api/using-graph-api/#search for building a place picker.
    content.placeId = "166793820034304"

    showShareDialog(content, mode: .Automatic)
  }

  @IBAction func showLinkShareDialogModeWeb() {
    var content = LinkShareContent(url: NSURL(string: "https://newsroom.fb.com/")!,
                                   title: "Name: Facebook News Room",
                                   description: "Description: The Facebook Swift SDK helps you develop Facebook integrated iOS apps.",
                                   imageURL: NSURL(string: "https://raw.github.com/fbsamples/ios-3.x-howtos/master/Images/iossdk_logo.png"))

    // placeId is hardcoded here, see https://developers.facebook.com/docs/graph-api/using-graph-api/#search for building a place picker.
    content.placeId = "166793820034304"

    showShareDialog(content, mode: .Web)
  }
}

//--------------------------------------
// MARK: - Photo Content
//--------------------------------------

extension ShareDialogViewController {

  @IBAction func showShareDialogPhotoContent() {
    let photo = Photo(image: UIImage(named: "sky.jpg")!, userGenerated: true)
    let content = PhotoShareContent(photos: [photo])
    showShareDialog(content)
  }
}

//--------------------------------------
// MARK: - Video Content
//--------------------------------------

extension ShareDialogViewController {

  @IBAction func showShareDialogVideoContent() {
    let imagePickerController = UIImagePickerController()
    imagePickerController.delegate = self
    imagePickerController.sourceType = .PhotoLibrary
    imagePickerController.mediaTypes = [kUTTypeMovie as String]
    presentViewController(imagePickerController, animated: true, completion: nil)
  }
}

extension ShareDialogViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
  func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
    picker.dismissViewControllerAnimated(true, completion: nil)

    guard let videoURL = info[UIImagePickerControllerReferenceURL] as? NSURL else {
      return
    }

    let video = Video(url: videoURL)
    let content = VideoShareContent(video: video)
    showShareDialog(content)
  }
}
