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

#if BUCK
import FacebookCore
#endif

import FBSDKCoreKit

public extension LoginConfiguration {

  /**
   Attempts to allocate and initialize a new configuration with the expected parameters.

   - parameter permissions: The requested permissions for the login attempt.
   Defaults to an empty `Permission` array.
   - parameter tracking: The tracking preference to use for a login attempt. Defaults to `.enabled`
   - parameter nonce: An optional nonce to use for the login attempt.
    A valid nonce must be an alphanumeric string without whitespace.
    Creation of the configuration will fail if the nonce is invalid. Defaults to a `UUID` string.
   - parameter messengerPageId: An optional page id to use for a login attempt. Defaults to `nil`
   - parameter authType: An optional auth type to use for a login attempt. Defaults to `.rerequest`
   */
  convenience init?(
    permissions: Set<Permission> = [],
    tracking: LoginTracking = .enabled,
    nonce: String = UUID().uuidString,
    messengerPageId: String? = nil,
    authType: LoginAuthType? = .rerequest
  ) {
    self.init(
      __permissions: permissions.map { $0.name },
      tracking: tracking,
      nonce: nonce,
      messengerPageId: messengerPageId,
      authType: authType
    )
  }
}
