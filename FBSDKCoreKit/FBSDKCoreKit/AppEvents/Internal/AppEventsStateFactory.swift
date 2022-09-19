/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

final class AppEventsStateFactory: _AppEventsStateProviding {
  func createState(tokenString: String, appID: String) -> _AppEventsState {
    _AppEventsState(token: tokenString, appID: appID)
  }
}
