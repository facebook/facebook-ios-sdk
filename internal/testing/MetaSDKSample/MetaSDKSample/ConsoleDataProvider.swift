/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import Foundation

class ConsoleDataProvider {

  private var messages: [String] = []

  private var currentDate: String {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy-MM-dd 'at' HH:mm:ss"
    return dateFormatter.string(from: Date())
  }

  func addMessage(message: String) {
    let newMessage = "\(currentDate) : \(message)"
    messages.append(newMessage)
  }

  func allMessages() -> [String] {
    return messages
  }
}
