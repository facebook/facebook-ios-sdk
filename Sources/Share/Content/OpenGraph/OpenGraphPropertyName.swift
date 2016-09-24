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
 Represents a type-safe OpenGraph property name.
 */
public struct OpenGraphPropertyName {
  /// The namespace of this open graph property
  public var namespace: String

  /// The name of this open graph property
  public var name: String

  /**
   Attempt to parse an `OpenGraphPropertyName` from a raw OpenGraph formatted property name.

   - parameter string: The string to create from.
   */
  public init?(_ string: String) {
    let components = string.characters.split(separator: ":")
    guard components.count >= 2 else {
      return nil
    }

    self.namespace = String(components[0])

    let subcharacters = components[1 ... components.count]
    self.name = subcharacters.reduce("", { $0 + ":" + String($1) })
  }

  /**
   Create an `OpenGraphPropertyName` with a specific namespace and name.

   - parameter namespace: The namespace to use.
   - parameter name:      The name to use.
   */
  public init(namespace: String, name: String) {
    self.namespace = namespace
    self.name = name
  }
}

extension OpenGraphPropertyName: RawRepresentable {
  public typealias RawValue = String

  /// The raw OpenGraph formatted property name.
  public var rawValue: String {
    return namespace.isEmpty
      ? name
      : namespace + ":" + name
  }

  /**
   Attempt to parse an `OpenGraphPropertyName` from a raw OpenGraph formatted proeprty name.

   - parameter rawValue: The string to create from.
   */
  public init(rawValue: String) {
    self.init(stringLiteral: rawValue)
  }
}

extension OpenGraphPropertyName: ExpressibleByStringLiteral {
  /**
   Create an `OpenGraphPropertyName` from a string literal.

   - parameter value: The string literal to create from.
   */
  public init(stringLiteral value: String) {
    guard let propertyName = OpenGraphPropertyName(value) else {
      print("Warning: Attempting to create OpenGraphPropertyName for string \"\(value)\", which has no namespace!")

      self.namespace = ""
      self.name = value
      return
    }

    self.namespace = propertyName.namespace
    self.name = propertyName.name
  }

  /**
   Create an `OpenGraphPropertyName` from a unicode scalar literal.

   - parameter value: The scalar literal to create from.
   */
  public init(unicodeScalarLiteral value: UnicodeScalarType) {
    self.init(stringLiteral: value)
  }

  /**
   Create an `OpenGraphPropertyName` from an grapheme cluster literal.

   - parameter value: The grapheme cluster to create from.
   */
  public init(extendedGraphemeClusterLiteral value: ExtendedGraphemeClusterType) {
    self.init(stringLiteral: value)
  }
}

extension OpenGraphPropertyName: Hashable {
  /// Calculates the hash value of this `OpenGraphPropertyName`.
  public var hashValue: Int {
    return rawValue.hashValue
  }

  /**
   Compares two `OpenGraphPropertyName`s for equality.

   - parameter lhs: The first property name to compare.
   - parameter rhs: The second property name to compare.

   - returns: Whether or not these names are equal.
   */
  public static func == (lhs: OpenGraphPropertyName, rhs: OpenGraphPropertyName) -> Bool {
    return lhs.rawValue == rhs.rawValue
  }
}
