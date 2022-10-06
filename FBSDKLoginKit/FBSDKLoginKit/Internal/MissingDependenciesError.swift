/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

struct MissingDependenciesError<Dependent>: Error, CustomStringConvertible {
  private let dependentType: Dependent.Type

  init(for dependentType: Dependent.Type) {
    self.dependentType = dependentType
  }

  var description: String {
    "The dependencies for the type '\(dependentType)' or an instance of it have not been set"
  }
}
