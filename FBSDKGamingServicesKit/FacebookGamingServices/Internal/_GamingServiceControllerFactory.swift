/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

/**
 Internal Type exposed to facilitate transition to Swift.
 API Subject to change or removal without warning. Do not use.

 @warning INTERNAL - DO NOT USE
 */
@objcMembers
@objc(FBSDKGamingServiceControllerFactory)
public class _GamingServiceControllerFactory: NSObject, _GamingServiceControllerCreating {
  public func create(
    with serviceType: _GamingServiceType,
    completion: @escaping GamingServiceResultCompletion,
    pendingResult: Any?
  ) -> _GamingServiceControllerProtocol {
    _GamingServiceController(
      serviceType: serviceType,
      completionHandler: completion,
      pendingResult: pendingResult as? [String: Any] ?? [:]
    )
  }
}
