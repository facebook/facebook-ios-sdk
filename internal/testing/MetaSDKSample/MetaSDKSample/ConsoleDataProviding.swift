/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import Foundation

protocol ConsoleDataProviding {
  var consoleDataManager: ConsoleDataProvider {get}
}

private let sharedConsoleDataManager: ConsoleDataProvider = ConsoleDataProvider()

extension ConsoleDataProviding {
  var consoleDataManager: ConsoleDataProvider {
    return sharedConsoleDataManager
  }
}
