/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import FacebookLogin

struct VerifyFacebookLogin {
    func verifyTransitiveSymbols() {
        // Verifies Swift only symbol
        _ = Permission.email

        // Verifies ObjC symbol
        Settings.appID = "Foo"

        // Additional Sanity Check
        AppEvents.logEvent(AppEvents.Name("foo"))
    }

    func verifyLoginSymbols() {
        // Verifies Swift only symbol
        _ = LoginResult.cancelled

        // Verifies Swift only initializer
        _ = LoginManager(defaultAudience: .everyone)

        // Verifies ObjC initializer
        _ = LoginManager()
    }
}
