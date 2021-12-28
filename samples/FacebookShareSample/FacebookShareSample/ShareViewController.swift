/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import FacebookShare
import UIKit

class ShareViewController: UITableViewController {

    @IBAction func shareLink() {
        guard let url = URL(string: "https://newsroom.fb.com/") else {
            preconditionFailure("URL is invalid")
        }

        let content = ShareLinkContent()
        content.contentURL = url
        content.hashtag = Hashtag("#bestSharingSampleEver")

        dialog(withContent: content).show()
    }

    @IBAction func sharePhoto() {
        #if targetEnvironment(simulator)
        presentAlert(
            title: "Error",
            message: "Sharing an image will not work on a simulator. Please build to a device and try again."
        )
        return
        #endif

        guard let image = UIImage(named: "puppy") else {
            presentAlert(
                title: "Invalid image",
                message: "Could not find image to share"
            )
            return
        }

        let photo = SharePhoto(image: image, userGenerated: true)
        let content = SharePhotoContent()
        content.photos = [photo]

        let dialog = self.dialog(withContent: content)

        // Recommended to validate before trying to display the dialog
        do {
            try dialog.validate()
        } catch {
            presentAlert(for: error)
        }

        dialog.show()
    }

    func dialog(withContent content: SharingContent) -> ShareDialog {
        return ShareDialog(
            viewController: self,
            content: content,
            delegate: self
        )
    }
}

extension ShareViewController: SharingDelegate {

    func sharer(_ sharer: Sharing, didCompleteWithResults results: [String : Any]) {
        print(results)
    }

    func sharer(_ sharer: Sharing, didFailWithError error: Error) {
        presentAlert(for: error)
    }

    func sharerDidCancel(_ sharer: Sharing) {
        presentAlert(title: "Cancelled", message: "Sharing cancelled")
    }


}
