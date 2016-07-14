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
import FBSDKShareKit
@testable import FacebookCore

/**
 An Open Graph action for sharing.
 */
public struct OpenGraphAction: Equatable {
  // TODO (richardross): Make ActionType an enum with common action types.
  /// The action type.
  public var type: String

  private var properties: [OpenGraphPropertyName : OpenGraphPropertyValue]

  /**
   Create an `OpenGraphAction` with a specific action type.

   - parameter type: The type of the action.
   */
  public init(type: String) {
    self.type = type
    self.properties = [:]
  }
}

extension OpenGraphAction: OpenGraphPropertyContaining {
  /// Get the property names contained in this container.
  public var propertyNames: Set<OpenGraphPropertyName> {
    return Set(properties.keys)
  }

  public subscript(key: OpenGraphPropertyName) -> OpenGraphPropertyValue? {
    get {
      return properties[key]
    }
    set {
      properties[key] = newValue
    }
  }
}

extension OpenGraphAction {
  internal var sdkActionRepresentation: FBSDKShareOpenGraphAction {
    let sdkAction = FBSDKShareOpenGraphAction()
    sdkAction.actionType = type
    sdkAction.parseProperties(properties.keyValueMap { key, value in
      (key.rawValue, value.openGraphPropertyValue)
      })

    return sdkAction
  }

  internal init(sdkAction: FBSDKShareOpenGraphAction) {
    self.type = sdkAction.actionType
    self.properties = [:]

    sdkAction.enumerateKeysAndObjectsUsingBlock { (key: String?, value: AnyObject?, stop) in
      guard let key = key.map(OpenGraphPropertyName.init(rawValue:)),
        let value = value.map(OpenGraphPropertyValueConverter.valueFrom) else {
          return
      }
      self.properties[key] = value
    }
  }
}

/**
 Compare two `OpenGraphAction`s for equality.

 - parameter lhs: The first action to compare.
 - parameter rhs: The second action to compare.

 - returns: Whether or not the actions are equal.
 */
public func == (lhs: OpenGraphAction, rhs: OpenGraphAction) -> Bool {
  return lhs.sdkActionRepresentation == rhs.sdkActionRepresentation
}
