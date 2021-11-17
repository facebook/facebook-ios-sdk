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
@objc(FBSDKGamingServiceType)
public enum _GamingServiceType: UInt { // swiftlint:disable:this type_name
  case friendFinder
  case mediaAsset
  case community
}
