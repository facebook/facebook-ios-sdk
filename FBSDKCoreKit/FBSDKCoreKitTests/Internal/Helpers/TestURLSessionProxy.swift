/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

@objcMembers
class TestURLSessionProxy: NSObject, URLSessionProxying {
  var delegateQueue: OperationQueue?
  /// The most recent captured completion
  var capturedCompletion: UrlSessionTaskBlock?
  /// The most recent captured request
  var capturedRequest: URLRequest?
  /// All captured requests for this networker instance
  var capturedRequests = [URLRequest]()
  var invalidateAndCancelCallCount = 0

  func execute(_ request: URLRequest, completionHandler handler: @escaping UrlSessionTaskBlock) {
    capturedRequest = request
    capturedRequests.append(request)
    capturedCompletion = handler
  }

  func invalidateAndCancel() {
    invalidateAndCancelCallCount += 1
  }
}
