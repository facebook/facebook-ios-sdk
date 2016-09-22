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

import Foundation

/**
 Enum that represents a Graph API read permission.
 Each permission has its own set of requirements and suggested use cases.
 See a full list at https://developers.facebook.com/docs/facebook-login/permissions
 */
public enum ReadPermission {
  /// Provides access to a subset of items that are part of a person's public profile.
  case publicProfile
  /// Provides access the list of friends that also use your app.
  case userFriends
  /// Provides access to the person's primary email address.
  case email
  /**
   Permission with a custom string value.
   See https://developers.facebook.com/docs/facebook-login/permissions for full list of available permissions.
   */
  case custom(String)
}

extension ReadPermission: PermissionRepresentable {
  internal var permissionValue: Permission {
    switch self {
    case .publicProfile: return "public_profile"
    case .userFriends: return "user_friends"
    case .email: return "email"
    case .custom(let string): return Permission(name: string)
    }
  }
}
