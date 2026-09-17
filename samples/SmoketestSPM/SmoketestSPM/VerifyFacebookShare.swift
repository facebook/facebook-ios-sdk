/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import FacebookCore
import FacebookShare

struct VerifyFacebookShare {
    func verifyTransitiveSymbols() {
        // Verifies Swift only symbol
        _ = Permission.email

        // Verifies ObjC symbol
        Settings.shared.appID = "Foo"

        // Additional Sanity Check
        AppEvents.shared.logEvent(AppEvents.Name("foo"))
    }

    func verifyShareSymbols() {
        // Verifies ObjC symbol
        _ = ShareDialog(viewController: nil, content: nil, delegate: nil)

        // Verifies Swift only symbol
        _ = ShareDialog.Mode.automatic.description
    }
}
