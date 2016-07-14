// Copyright (c) 2016-present, Facebook, Inc. All rights reserved.
//
// You are hereby granted a non-exclusive, worldwide, royalty-free license to use,
// copy, modify, and distribute this software in source code or binary form for use
// in connection with the web services and APIs provided by Facebook.
//
// As with any software that integrates with the Facebook platform, your use of
// this software is subject to the Facebook Developer Principles and Policies
// [http://developers.facebook.com/policy/]. This copyright notice shall be
// included in all copies or substantial portions of the software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
// FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
// COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
// IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
// CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

import FBSDKCoreKit.FBSDKSettings

/**
 Defines logging behavior used by the SDK.
 To set/enable/disable specific behaviors use `Settings.loggingBehaviors`.
 */
public enum SDKLoggingBehavior {
  /// Include access token in logging.
  case AccessTokens

  /// Log performance characteristics
  case PerformanceCharacteristics

  /// Log `AppEventsLogger` interactions.
  case AppEvents

  /// Log informational occurences.
  case Informational

  /// Log cache errors.
  case CacheErrors

  /// Log errors from SDK UI controls.
  case UIControlErrors

  /// Log debug warnings from API responses, e.g. when friends fields were requested, but `user_friends` permissions isn't granted.
  case GraphAPIDebugWarning

  /**
   Log warnings from API responses, e.g. when requested feature will be deprecated in next version of API.
   Info is the lowest level of severity, using it will result in logging all previously mentioned levels.
   */
  case GraphAPIDebugInfo

  /// Log errors from SDK network requests.
  case NetworkRequests

  /// Log errors likely to be preventable by the developer. This behavior is enabled by default.
  case DeveloperErrors
}

extension SDKLoggingBehavior {
  internal init?(sdkStringValue: String) {
    switch sdkStringValue {
    case FBSDKLoggingBehaviorAccessTokens: self = .AccessTokens
    case FBSDKLoggingBehaviorPerformanceCharacteristics: self = .PerformanceCharacteristics
    case FBSDKLoggingBehaviorAppEvents: self = .AppEvents
    case FBSDKLoggingBehaviorInformational: self = .Informational
    case FBSDKLoggingBehaviorCacheErrors: self = .CacheErrors
    case FBSDKLoggingBehaviorUIControlErrors: self = .UIControlErrors
    case FBSDKLoggingBehaviorGraphAPIDebugWarning: self = .GraphAPIDebugWarning
    case FBSDKLoggingBehaviorGraphAPIDebugInfo: self = .GraphAPIDebugInfo
    case FBSDKLoggingBehaviorNetworkRequests: self = .NetworkRequests
    case FBSDKLoggingBehaviorDeveloperErrors: self = .DeveloperErrors
    default: return nil
    }
  }

  internal var sdkStringValue: String {
    switch self {
    case .AccessTokens: return FBSDKLoggingBehaviorAccessTokens
    case .PerformanceCharacteristics: return FBSDKLoggingBehaviorPerformanceCharacteristics
    case .AppEvents: return FBSDKLoggingBehaviorAppEvents
    case .Informational: return FBSDKLoggingBehaviorInformational
    case .CacheErrors: return FBSDKLoggingBehaviorCacheErrors
    case .UIControlErrors: return FBSDKLoggingBehaviorUIControlErrors
    case .GraphAPIDebugWarning: return FBSDKLoggingBehaviorGraphAPIDebugWarning
    case .GraphAPIDebugInfo: return FBSDKLoggingBehaviorGraphAPIDebugInfo
    case .NetworkRequests: return FBSDKLoggingBehaviorNetworkRequests
    case .DeveloperErrors: return FBSDKLoggingBehaviorDeveloperErrors
    }
  }
}
