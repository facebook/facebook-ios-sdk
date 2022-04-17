/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import Foundation

import FBSDKCoreKit_Basics

@objc(FBSDKCAPIReporter)
public protocol CAPIReporter {
    func enable()

    func configure(factory: GraphRequestFactoryProtocol, settings: SettingsProtocol)

    func recordEvent(_ parameters: [String: Any])
}
