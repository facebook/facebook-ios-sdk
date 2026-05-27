/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import FBSDKCoreKit
import Foundation

/// Configuration for the exponential-backoff retry strategy used by
/// `RefreshRetryHandler`. All time values are in seconds.
enum RetryConfig {
  static let maxRetries = 3
  static let initialDelay: TimeInterval = 1.0
  static let maxDelay: TimeInterval = 30.0
  static let backoffMultiplier = 2.0
  static let jitterRange = 0.2

  static func delay(forAttempt attempt: Int) -> TimeInterval {
    guard attempt > 0 else { return 0 }
    let baseDelay = initialDelay * pow(backoffMultiplier, Double(attempt - 1))
    let cappedDelay = min(baseDelay, maxDelay)
    let jitter = cappedDelay * jitterRange * Double.random(in: -1 ... 1)
    return cappedDelay + jitter
  }
}

final class RefreshRetryHandler {
  private var currentAttempt = 0

  func isRetryable(_ error: LimitedLoginRefreshError) -> Bool {
    switch error {
    case .networkError, .timeout:
      return true
    case .invalidResponse:
      return currentAttempt == 0
    case .loginRequired, .consentRequired, .userMismatch,
         .rateLimited, .cancelled, .noCurrentToken, .notLimitedLogin,
         .featureDisabled, .unsupportedPlatform, .notDPoPBound, .unknown:
      return false
    }
  }

  var attemptCount: Int { currentAttempt }

  func executeWithRetry(
    operation: @escaping (@escaping (Result<Profile, LimitedLoginRefreshError>) -> Void) -> Void,
    completion: @escaping (Result<Profile, LimitedLoginRefreshError>) -> Void
  ) {
    currentAttempt = 0
    attemptOperation(operation: operation, completion: completion)
  }

  private func attemptOperation(
    operation: @escaping (@escaping (Result<Profile, LimitedLoginRefreshError>) -> Void) -> Void,
    completion: @escaping (Result<Profile, LimitedLoginRefreshError>) -> Void
  ) {
    currentAttempt += 1

    operation { [weak self] result in
      guard let self = self else { return }

      switch result {
      case .success:
        completion(result)
      case let .failure(error):
        if self.isRetryable(error), self.currentAttempt < RetryConfig.maxRetries {
          let delay = RetryConfig.delay(forAttempt: self.currentAttempt)
          DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            self.attemptOperation(operation: operation, completion: completion)
          }
        } else {
          completion(result)
        }
      }
    }
  }

  func reset() {
    currentAttempt = 0
  }
}
