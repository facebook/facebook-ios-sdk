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

import FBSDKShareKit
@testable import FacebookCore

/**
 An Open Graph Object for sharing.

 The property keys MUST have namespaces specified on them, such as `og:image`, and `og:type` is required.

 See https://developers.facebook.com/docs/sharing/opengraph/object-properties for other properties.

 You can specify nested namespaces inline to define complex properties. For example, the following code will generate a
 fitness.course object with a location:

 ```
 let course: OpenGraphObject = [
 "og:type": "fitness.course",
 "og:title": "Sample course",
 "fitness:metrics:location:latitude": "41.40338",
 "fitness:metrics:location:longitude": "2.17403",
 ]
 ```
 */
public struct OpenGraphObject {
  fileprivate var properties: [OpenGraphPropertyName : OpenGraphPropertyValue]

  /**
   Create a new `OpenGraphObject`.
   */
  public init() {
    properties = [:]
  }
}

extension OpenGraphObject: OpenGraphPropertyContaining {
  /// Get the property names contained in this container.
  public var propertyNames: Set<OpenGraphPropertyName> {
    return Set(properties.keys)
  }

  public subscript(key: OpenGraphPropertyName) -> OpenGraphPropertyValue? {
    get {
      return properties[key]
    } set {
      properties[key] = newValue
    }
  }
}

extension OpenGraphObject: ExpressibleByDictionaryLiteral {
  /**
   Convenience method to build a new object from a dictinary literal.

   - parameter elements: The elements of the dictionary literal to initialize from.

   - example:
   ```
   let object: OpenGraphObject = [
   "og:type": "foo",
   "og:title": "bar",
   ....
   ]
   ```
   */
  public init(dictionaryLiteral elements: (OpenGraphPropertyName, OpenGraphPropertyValue)...) {
    properties = [:]
    for (key, value) in elements {
      properties[key] = value
    }
  }
}

extension OpenGraphObject {
  internal var sdkGraphObjectRepresentation: FBSDKShareOpenGraphObject {
    let sdkObject = FBSDKShareOpenGraphObject()
    sdkObject.parseProperties(properties.keyValueMap { key, value in
      (key.rawValue, value.openGraphPropertyValue)
    })
    return sdkObject
  }

  internal init(sdkGraphObject: FBSDKShareOpenGraphObject) {
    var properties = [OpenGraphPropertyName : OpenGraphPropertyValue]()
    sdkGraphObject.enumerateKeysAndObjects { (key: String?, value: Any?, stop) in
      guard let key = key.map(OpenGraphPropertyName.init(rawValue:)),
        let value = value.map(OpenGraphPropertyValueConverter.valueFrom) else {
          return
      }
      properties[key] = value
    }
    self.properties = properties
  }
}

extension OpenGraphObject: Equatable {
  /**
   Compare two `OpenGraphObject`s for equality.

   - parameter lhs: The first `OpenGraphObject` to compare.
   - parameter rhs: The second `OpenGraphObject` to compare.

   - returns: Whether or not the objects are equal.
   */
  public static func == (lhs: OpenGraphObject, rhs: OpenGraphObject) -> Bool {
    return false
  }
}
