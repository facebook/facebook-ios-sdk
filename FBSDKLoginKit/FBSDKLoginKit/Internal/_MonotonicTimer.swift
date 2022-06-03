/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !os(tvOS)

import Foundation

/**
 Internal type exposed to facilitate transition to Swift.
 API Subject to change or removal without warning. Do not use.

 @warning INTERNAL - DO NOT USE
 */
@objcMembers
public final class _MonotonicTimer: NSObject {
  private static let timebaseInfo: mach_timebase_info = {
    var info = mach_timebase_info()
    guard mach_timebase_info(&info) == 0 else {
      fatalError("Unable to get timebase information for monotomic timing")
    }

    return info
  }()

  private func getNanoseconds() -> UInt64 {
    (mach_absolute_time() * UInt64(Self.timebaseInfo.numer)) / UInt64(Self.timebaseInfo.denom)
  }

  public func getCurrentSeconds() -> TimeInterval {
    Double(getNanoseconds()) / 1_000_000_000.0
  }
}

#endif
