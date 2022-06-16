/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !os(tvOS)

protocol LoginCompleterFactoryProtocol {
  func createLoginCompleter(urlParameters parameters: [String: Any], appID: String) -> _LoginCompleting
}

#endif
