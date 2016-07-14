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

final class MainCollectionViewController: UICollectionViewController {
  private let iconArray = [
    Item(text: "Login", iconImageName: "LoginIcon"),
    Item(text: "Share", iconImageName: "ShareIcon"),
    Item(text: "App Events", iconImageName: "AppEventsIcon"),
    Item(text: "App Invites", iconImageName: "AppInvitesIcon"),
    Item(text: "Graph API", iconImageName: "GraphAPIIcon")
  ]

  override func viewWillAppear(animated: Bool) {
    super.viewWillAppear(animated)
    navigationController?.navigationBar.hidden = true
  }

  override func viewWillDisappear(animated: Bool) {
    super.viewWillDisappear(animated)
    navigationController?.navigationBar.hidden = false
  }
}

//--------------------------------------
// MARK: - UICollectionViewDataSource
//--------------------------------------

extension MainCollectionViewController {
  override func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
    return 1
  }

  override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return iconArray.count
  }

  override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
    let cell = collectionView.dequeueReusableCellWithReuseIdentifier("cell", forIndexPath: indexPath)
    if let menuCell = cell as? MainCollectionViewCell {
      menuCell.updateFrom(iconArray[indexPath.row])
    } else {
      fatalError("CollectionView provided wrong cell for indexPath \(indexPath)")
    }
    return cell
  }
}

//--------------------------------------
// MARK: - UICollectionViewDelegate
//--------------------------------------

extension MainCollectionViewController {
  override func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
    performSegueWithIdentifier(iconArray[indexPath.row].text, sender: self)
  }
}

//--------------------------------------
// MARK: - Types
//--------------------------------------

extension MainCollectionViewController {
  struct Item {
    var text: String
    var iconImageName: String

    var image: UIImage? {
      return UIImage(named: iconImageName)
    }
  }
}
