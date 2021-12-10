/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import Foundation

enum SampleGraphResponses {
  case empty
  case nonJSON
  case utf8String
  case dictionary

  var unserialized: Any? {
    switch self {
    case .empty, .nonJSON:
      return nil

    case .utf8String:
      return "top level type"

    case .dictionary:
      return ["name": "bob"]
    }
  }

  var data: Data {
    switch self {
    case .empty:
      return Data()

    case .nonJSON:
      return withUnsafeBytes(of: 100.0) { Data($0) }

    case .utf8String:
      return (unserialized as! String).data(using: .utf8)! // swiftlint:disable:this force_cast force_unwrapping

    case .dictionary:
      return try! JSONSerialization.data(  // swiftlint:disable:this force_try
        withJSONObject: unserialized as Any,
        options: []
      )
    }
  }
}
