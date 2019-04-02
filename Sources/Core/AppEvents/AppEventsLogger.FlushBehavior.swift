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

import FBSDKCoreKit.FBSDKAppEvents

public extension AppEventsLogger {
  /**
   Specifies when `AppEventsLogger` sends log events to the server.
   */
  enum FlushBehavior {
    /**
     Flush automatically: periodically (once a minute or every 100 logged events) and always at app reactivation.
     */
    case auto

    /**
     Only flush when the `flush` method is called.
     When an app is moved to background/terminated, the events are persisted and re-established at activation,
     but they will only be written with an explicit call to `flush`.
     */
    case explicitOnly

    internal init(sdkFlushBehavior: FBSDKAppEventsFlushBehavior) {
      switch sdkFlushBehavior {
      case .auto: self = .auto
      case .explicitOnly: self = .explicitOnly
      @unknown default:
        assertionFailure("Unknown Case")
        self = .auto
      }
    }

    internal var sdkFlushBehavior: FBSDKAppEventsFlushBehavior {
      switch self {
      case .auto: return .auto
      case .explicitOnly: return .explicitOnly
      }
    }
  }
}
