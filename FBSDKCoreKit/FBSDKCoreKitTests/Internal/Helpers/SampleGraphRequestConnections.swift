/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import Foundation
import TestTools

@testable import FBSDKCoreKit

@objcMembers
class SampleGraphRequestConnections: NSObject {

  static var empty: GraphRequestConnecting {
    TestGraphRequestConnection()
  }

  static func with(requests: [GraphRequestProtocol]) -> GraphRequestConnecting {
    let connection = TestGraphRequestConnection()
    requests.forEach {
      connection.add($0) { _, _, _ in }
    }
    return connection
  }
}

@objc
extension TestGraphRequestConnection: _FBSDKGraphRequestConnecting {
  public var requests: NSMutableArray {
    NSMutableArray(
      array: graphRequests.compactMap {
        GraphRequestMetadata(
          request: $0.request,
          completionHandler: $0.completion,
          batchParameters: nil
        )
      }
    )
  }
}
