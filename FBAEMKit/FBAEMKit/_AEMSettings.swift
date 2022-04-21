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
public final class _AEMSettings: NSObject {
  public static func appID() -> String? {
    guard let bundle = try? getDependencies().bundle else {
      return nil
    }

    return bundle.object(forInfoDictionaryKey: "FacebookAppID") as? String
  }
}

extension _AEMSettings: DependentAsType {
  struct TypeDependencies {
    var bundle: Bundle
  }

  static var configuredDependencies: TypeDependencies?

  static var defaultDependencies: TypeDependencies? = TypeDependencies(bundle: .main)
}

#endif
