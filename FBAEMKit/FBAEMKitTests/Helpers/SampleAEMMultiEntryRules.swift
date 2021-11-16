/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import FBAEMKit
import Foundation

enum SampleAEMMultiEntryRules {

  private static let factory = AEMAdvertiserRuleFactory()

  static let contentRule =
    factory.createRule(withJson: "{\"or\":[{\"fb_content[*].id\":{\"eq\":\"12345\"}}]}")! // swiftlint:disable:this line_length force_unwrapping
}
