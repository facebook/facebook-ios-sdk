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

final class ShareAPIViewController: UITableViewController {

  func share<C: ContentProtocol>(_ content: C) {
    var title: String = ""
    var message: String = ""

    do {
      try GraphSharer.share(content) { result in
        switch result {
        case .success(let contentResult):
          title = "Share Success"
          message = "Succesfully shared: \(contentResult)"
        case .cancelled:
          title = "Share Cancelled"
          message = "Sharing was cancelled by user."
        case .failed(let error):
          title = "Share Failed"
          message = "Sharing failed with error \(error)"
        }
        let alertController = UIAlertController(title: title, message: message)
        self.present(alertController, animated: true, completion: nil)
      }
    } catch (let error) {
      title = "Share API Fail"
      message = "Failed to invoke share API with error: \(error)"
      let alertController = UIAlertController(title: title, message: message)
      present(alertController, animated: true, completion: nil)
    }
  }
}

//--------------------------------------
// MARK: - Link Content
//--------------------------------------

extension ShareAPIViewController {
  @IBAction func shareLink() {
    let content = LinkShareContent(url: URL(string: "https://newsroom.fb.com/")!,
                                   title: "Name: Facebook News Room",
                                   description: "Description: The Facebook Swift SDK helps you develop Facebook integrated iOS apps.",
                                   imageURL: URL(string: "https://raw.github.com/fbsamples/ios-3.x-howtos/master/Images/iossdk_logo.png"))
    share(content)
  }
}

//--------------------------------------
// MARK: - Photo Content
//--------------------------------------

extension ShareAPIViewController {
  @IBAction func sharePhoto() {
    let photo = Photo(image: UIImage(named: "sky.jpg")!, userGenerated: true)
    let content = PhotoShareContent(photos: [photo])
    share(content)
  }
}

//--------------------------------------
// MARK: - Video Content
//--------------------------------------

extension ShareAPIViewController {
  @IBAction func shareVideo() {
    let video = Video(url: Bundle.main.url(forResource: "sky", withExtension: "mp4")!)
    let content = VideoShareContent(video: video)
    share(content)
  }
}
