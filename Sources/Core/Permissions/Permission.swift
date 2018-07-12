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
 Represents a Graph API permission.
 Each permission has its own set of requirements and suggested use cases.
 See a full list at https://developers.facebook.com/docs/facebook-login/permissions
 */
public struct Permission: Hashable, ExpressibleByStringLiteral {

  /// Name of the permission.
  public let name: String

  /**
   Create a permission with a string value.

   - parameter name: Name of the permission.
   */
  public init(name: String) {
    self.name = name
  }

  // MARK: ExpressibleByStringLiteral

  /**
   Create a permission with a string value.

   - parameter value: String literal representation of the permission.
   */
  public init(stringLiteral value: StringLiteralType) {
    self.init(name: value)
  }

  /**
   Create a permission with a string value.

   - parameter value: String literal representation of the permission.
   */
  public init(unicodeScalarLiteral value: String) {
    self.init(name: value)
  }

  /**
   Create a permission with a string value.

   - parameter value: String literal representation of the permission.
   */
  public init(extendedGraphemeClusterLiteral value: String) {
    self.init(name: value)
  }

  // MARK: Hashable

  /// The hash value.
  public var hashValue: Int {
    return name.hashValue
  }

  /**
   Compare two `Permission`s for equality.

   - parameter lhs: The first permission to compare.
   - parameter rhs: The second permission to compare.

   - returns: Whether or not the permissions are equal.
   */
  public static func == (lhs: Permission, rhs: Permission) -> Bool {
    return lhs.name == rhs.name
  }
}

internal protocol PermissionRepresentable {
  var permissionValue: Permission { get }
}
