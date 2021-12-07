/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

final class TestSharingDelegate: SharingDelegate {
  var capturedError: Error?

  func sharer(_ sharer: Sharing, didCompleteWithResults results: [String: Any]) {
    // empty
  }

  func sharer(_ sharer: Sharing, didFailWithError error: Error) {
    capturedError = error
  }

  func sharerDidCancel(_ sharer: Sharing) {
    // empty
  }
}
