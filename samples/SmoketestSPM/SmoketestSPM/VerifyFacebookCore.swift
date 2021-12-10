/*
 * Copyright (c) Facebook, Inc. and its affiliates.
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
        Settings.appID = "Foo"

        // Additional Sanity Check
        AppEvents.logEvent(AppEvents.Name("foo"))
    }
}
