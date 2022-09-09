/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import Foundation

protocol WebAuthenticating {
  func authenticate(parameters: WebAuthenticationParameters) async throws -> URL
}

struct WebAuthenticationParameters {
  let url: URL
  let callbackScheme: String?
}
