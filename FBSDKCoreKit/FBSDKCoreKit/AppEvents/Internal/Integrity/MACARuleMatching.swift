/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import Foundation

@objc(FBSDKMACARuleMatching)
public protocol MACARuleMatching {
  @objc func enable()
  @objc func processParameters(_ params: NSDictionary?, event: String?) -> NSDictionary?
}
