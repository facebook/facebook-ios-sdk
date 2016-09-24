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
  fileprivate let iconArray = [
    Item(text: "Login", iconImageName: "LoginIcon"),
    Item(text: "Share", iconImageName: "ShareIcon"),
    Item(text: "App Events", iconImageName: "AppEventsIcon"),
    Item(text: "App Invites", iconImageName: "AppInvitesIcon"),
    Item(text: "Graph API", iconImageName: "GraphAPIIcon")
  ]

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    navigationController?.navigationBar.isHidden = true
  }

  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    navigationController?.navigationBar.isHidden = false
  }
}

//--------------------------------------
// MARK: - UICollectionViewDataSource
//--------------------------------------

extension MainCollectionViewController {
  override func numberOfSections(in collectionView: UICollectionView) -> Int {
    return 1
  }

  override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return iconArray.count
  }

  override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath)
    if let menuCell = cell as? MainCollectionViewCell {
      menuCell.updateFrom(iconArray[(indexPath as NSIndexPath).row])
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
  override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    performSegue(withIdentifier: iconArray[(indexPath as NSIndexPath).row].text, sender: self)
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
