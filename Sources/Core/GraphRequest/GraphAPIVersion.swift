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

import FBSDKCoreKit

/**
 Represents version of the Facebook Graph API.

 To find out the current latest version - refer to https://developers.facebook.com/docs/graph-api/overview
 */
public struct GraphAPIVersion {
  /// String representation of an api version.
  public let stringValue: String

  /**
   Represents the default Graph API version.
   Note: This value may change between versions of the SDK.
   */
  public static let defaultVersion: GraphAPIVersion = {
    var version = FBSDK_TARGET_PLATFORM_VERSION
    // ObjC SDK has a prefix of `v` on this constant
    if version.hasPrefix("v") {
      version = String(version.characters.dropFirst())
    }
    return GraphAPIVersion(stringLiteral: version)
  }()
}

extension GraphAPIVersion: ExpressibleByStringLiteral {

  /**
   Create a `GraphAPIVersion` from a string literal.

   - parameter value: The string literal to create from.
   */
  public init(stringLiteral value: StringLiteralType) {
    stringValue = value
  }

  /**
   Create a `GraphAPIVersion` from a unicode scalar literal.

   - parameter value: The string literal to create from.
   */
  public init(unicodeScalarLiteral value: String) {
    self.init(stringLiteral: value)
  }

  /**
   Create a `GraphAPIVersion` from an extended grapheme cluster.

   - parameter value: The string literal to create from.
   */
  public init(extendedGraphemeClusterLiteral value: String) {
    self.init(stringLiteral: value)
  }
}

extension GraphAPIVersion: ExpressibleByFloatLiteral {

  /**
   Create a `GraphAPIVersion` from a float literal.

   - parameter value: The float literal to create from.
   */
  public init(floatLiteral value: FloatLiteralType) {
    stringValue = String(format: "%.1f", value)
  }
}
