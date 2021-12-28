/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import UIKit

class TestTableView: UITableView {
  var stubbedWindow: UIWindow?
  var stubbedCellMap = [IndexPath: UITableViewCell]()

  func stub(cell: UITableViewCell, forIndexPath indexPath: IndexPath) {
    stubbedCellMap[indexPath] = cell
  }

  override func cellForRow(at indexPath: IndexPath) -> UITableViewCell? {
    stubbedCellMap[indexPath]
  }

  override var window: UIWindow? {
    stubbedWindow
  }
}
