/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import FacebookShare

struct VerifyFacebookShare {
    func verifyTransitiveSymbols() {
        // Verifies Swift only symbol
        _ = Permission.email

        // Verifies ObjC symbol
        Settings.appID = "Foo"

        // Additional Sanity Check
        AppEvents.logEvent(AppEvents.Name("foo"))
    }

    func verifyShareSymbols() {
        // Verifies ObjC symbol
        _ = ShareDialog()

        // Verifies Swift only symbol
        _ = ShareDialog.Mode.automatic.description
    }
}
