/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import Foundation

struct SwizzleEvidence: Equatable {
  let selector: Selector
  let `class`: AnyClass

  init(
    selector: Selector,
    class: AnyClass
  ) {
    self.selector = selector
    self.class = `class`
  }

  static func == (lhs: SwizzleEvidence, rhs: SwizzleEvidence) -> Bool {
    lhs.selector == rhs.selector && lhs.class == rhs.class
  }
}

@objcMembers
final class TestSwizzler: NSObject, Swizzling {
  static var evidence = [SwizzleEvidence]()

  static func swizzleSelector(
    _ aSelector: Selector,
    on aClass: AnyClass,
    with block: @escaping swizzleBlock,
    named aName: String
  ) {
    evidence.append(.init(selector: aSelector, class: aClass))
  }

  static func reset() {
    evidence = []
  }
}
