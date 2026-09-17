/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import FacebookCore

struct VerifyFacebookCore {
    func verifySymbols() {
        // Verifies Swift only symbol
        _ = Permission.email

        // Verifies ObjC symbol
        Settings.shared.appID = "Foo"

        // Additional Sanity Check
        AppEvents.shared.logEvent(AppEvents.Name("foo"))
    }
}
