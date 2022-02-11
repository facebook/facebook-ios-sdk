/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import FacebookCore
import UIKit

final class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        guard let context = URLContexts.first else {
            fatalError("Open url called without a context. This should never happen.")
        }

        ApplicationDelegate.shared.application(
            UIApplication.shared,
            open: context.url,
            sourceApplication: nil,
            annotation: nil
        )
    }
}
