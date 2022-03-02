/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

protocol _ConfigurableType {
  associatedtype Dependencies

  static var configuredDependencies: Dependencies? { get set }
  static var defaultDependencies: Dependencies? { get }

  static func configure(with dependencies: Dependencies)

  #if DEBUG
  static func unconfigure()
  #endif
}

extension _ConfigurableType {
  static func configure(with dependencies: Dependencies) {
    configuredDependencies = dependencies
  }

  #if DEBUG
  static func unconfigure() {
    configuredDependencies = nil
  }
  #endif

  static func getDependencies() throws -> Dependencies {
    guard let validDependencies = configuredDependencies ?? defaultDependencies else {
      throw _UnconfiguredTypeError(for: Self.self)
    }

    return validDependencies
  }
}

struct _UnconfiguredTypeError<ConfigurableType: _ConfigurableType>: Error, CustomStringConvertible {
  private var configurableType: ConfigurableType.Type

  fileprivate init(for configurableType: ConfigurableType.Type) {
    self.configurableType = configurableType
  }

  var description: String {
    "The type '\(configurableType)' has not been configured"
  }
}
