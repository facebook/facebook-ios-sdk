/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

// Need to treat ObjC as separate dependency for SPM because it does not
// support mixed Swift and ObjC sources. In order to expose the dependent
// interface we need to pass through the import of the `FBSDKShareKitObjC`
// target defined in Package.swift.
// See: https://forums.swift.org/t/16648/2 for more details
//

#if canImport(FBSDKCoreKit)
@_exported import FBSDKCoreKit
#endif
