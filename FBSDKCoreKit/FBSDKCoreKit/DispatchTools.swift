//
//  DispatchTools.swift
//  FBSDKCoreKit
//
//  Created by Narek Sahakyan on 11.10.23.
//  Copyright © 2023 Facebook. All rights reserved.
//

import Foundation

@objcMembers
@objc(FBSDKDispatchTools)
public final class DispatchTools: NSObject {
  /// Perform synchronous task on background thread.
  /// - Parameters:
  ///   - timeout: The latest time to wait for a task.
  ///   - block: The block to be invoked on the global queue with userInteractive priority.
  /// - Returns: A value of returned task or nil if timeout with pass.
  public static func performSyncOnBackground(timeout: TimeInterval, block: @escaping () -> ()) {
    let semaphore = DispatchSemaphore(value: 0)

    DispatchQueue.global(qos: .userInteractive).async {
      block()
      semaphore.signal()
    }

    _ = semaphore.wait(timeout: .now() + timeout)
  }
}
