/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

final class AppLinkFactory: _AppLinkCreating {
  func createAppLink(
    sourceURL: URL?,
    targets: [AppLinkTargetProtocol],
    webURL: URL?,
    isBackToReferrer: Bool
  ) -> _AppLinkProtocol {
    AppLink(
      sourceURL: sourceURL,
      targets: targets,
      webURL: webURL,
      isBackToReferrer: isBackToReferrer
    )
  }
}
