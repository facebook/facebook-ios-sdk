/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !os(tvOS)

/**
 Internal Type exposed to facilitate transition to Swift.
 API Subject to change or removal without warning. Do not use.

 @warning INTERNAL - DO NOT USE
 */
@objcMembers
@objc(FBAEMSettings)
public final class AEMSettings: NSObject {
  public static func appID() -> String? {
    Bundle.main.object(forInfoDictionaryKey: "FacebookAppID") as? String
  }
}

#endif
