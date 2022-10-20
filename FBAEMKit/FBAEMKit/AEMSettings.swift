/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !os(tvOS)

import Foundation

final class AEMSettings: NSObject {
  static func appID() -> String? {
    // swiftformat:disable:next redundantSelf
    self.bundle?.object(forInfoDictionaryKey: "FacebookAppID") as? String
  }
}

extension AEMSettings: DependentAsType {
  struct TypeDependencies {
    var bundle: Bundle
  }

  static var configuredDependencies: TypeDependencies?

  static var defaultDependencies: TypeDependencies? = TypeDependencies(bundle: .main)
}

#endif
