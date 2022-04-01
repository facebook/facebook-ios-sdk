/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import FBSDKShareKit

final class TestSharingDelegate: SharingDelegate {
  var sharerDidCompleteCalled = false
  var sharerDidCompleteSharer: Sharing?
  var sharerDidCompleteResults: [String: Any]?

  func sharer(_ sharer: Sharing, didCompleteWithResults results: [String: Any]) {
    sharerDidCompleteCalled = true
    sharerDidCompleteSharer = sharer
    sharerDidCompleteResults = results
  }

  var sharerDidFailCalled = false
  var sharerDidFailSharer: Sharing?
  var sharerDidFailError: Error?

  func sharer(_ sharer: Sharing, didFailWithError error: Error) {
    sharerDidFailCalled = true
    sharerDidFailSharer = sharer
    sharerDidFailError = error
  }

  var sharerDidCancelCalled = false
  var sharerDidCancelSharer: Sharing?

  func sharerDidCancel(_ sharer: Sharing) {
    sharerDidCancelCalled = true
    sharerDidCancelSharer = sharer
  }
}
