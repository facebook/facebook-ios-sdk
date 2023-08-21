/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import UIKit

final class TestCollectionView: UICollectionView {
  var stubbedWindow: UIWindow?
  var stubbedCellMap = [IndexPath: UICollectionViewCell]()

  func stub(cell: UICollectionViewCell, forIndexPath indexPath: IndexPath) {
    stubbedCellMap[indexPath] = cell
  }

  override func cellForItem(at indexPath: IndexPath) -> UICollectionViewCell? {
    stubbedCellMap[indexPath]
  }

  override var window: UIWindow? {
    stubbedWindow
  }
}
