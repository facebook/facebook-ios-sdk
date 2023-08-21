/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

extension Comparable {
  func fb_clamped(to range: ClosedRange<Self>) -> Self {
    min(max(range.lowerBound, self), range.upperBound)
  }
}
