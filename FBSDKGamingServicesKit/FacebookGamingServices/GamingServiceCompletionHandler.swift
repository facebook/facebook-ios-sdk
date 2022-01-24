/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import Foundation

/**
 Main completion handling of any Gaming Service (Friend Finder, Image/Video Upload).

 @param success whether the call to the service was considered a success.
 @param error the error that occured during the service call, if any.
 */
public typealias GamingServiceCompletionHandler = (_ success: Bool, _ error: Error?) -> Void
public typealias FBSDKGamingServiceCompletionHandler = GamingServiceCompletionHandler

/**
 Main completion handling of any Gaming Service (Friend Finder, Image/Video Upload).

 @param success whether the call to the service was considered a success.
 @param result the result that was returned by the service, if any.
 @param error the error that occured during the service call, if any.
 */
public typealias GamingServiceResultCompletion = (_ success: Bool, _ result: [String: Any]?, _ error: Error?) -> Void
public typealias FBSDKGamingServiceResultCompletion = GamingServiceResultCompletion
/**
 Main completion handling of any Gaming Service (Friend Finder, Image/Video Upload).

 @param bytesSent the number of bytes sent since the last invocation
 @param totalBytesSent the total number of bytes sent
 @param totalBytesExpectedToSend the number of bytes that remain to be sent
 */
public typealias GamingServiceProgressHandler = (
  _ bytesSent: Int64,
  _ totalBytesSent: Int64,
  _ totalBytesExpectedToSend: Int64
) -> Void
public typealias FBSDKGamingServiceProgressHandler = GamingServiceProgressHandler
