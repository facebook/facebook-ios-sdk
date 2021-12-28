/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import Foundation

enum DateFormatter {
  @available(iOS 10.0, *)
  static var isoFormatter = ISO8601DateFormatter()
  static var formatter: Foundation.DateFormatter {
    let formatter = Foundation.DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
    return formatter
  }

  static func format(ISODateString date: String) -> Date? {
    if #available(iOS 10.0, *) {
      return self.isoFormatter.date(from: date)
    }
    return formatter.date(from: date)
  }
}
