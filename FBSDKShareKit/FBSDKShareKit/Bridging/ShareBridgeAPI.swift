/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import Foundation

enum ShareBridgeAPI {
  enum MethodName {
    static let camera = "camera"
    static let share = "share"
  }

  enum CompletionGesture {
    static let key = "completionGesture"
    static let cancelValue = "cancel"
  }

  enum PostIDKey {
    static let results = "postId"
    static let webParameters = "post_id"
  }
}
