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
 Protocol defining operations on open graph actions and objects.
 */
public protocol OpenGraphPropertyContaining {
  /// Get the property names contained in this container.
  var propertyNames: Set<OpenGraphPropertyName> { get }

  /**
   Get the value corresponding to a given property name.

   - parameter name: The property name to retrieve.

   - returns: The value for the given property.
   */
  subscript(name: OpenGraphPropertyName) -> OpenGraphPropertyValue? { get set }
}

public extension OpenGraphPropertyContaining {
  subscript(key: OpenGraphPropertyName) -> String? {
    let graphValue: OpenGraphPropertyValue? = self[key]
    return graphValue as? String
  }

  subscript(key: OpenGraphPropertyName) -> NSNumber? {
    let graphValue: OpenGraphPropertyValue? = self[key]
    return graphValue as? NSNumber
  }

  subscript(key: OpenGraphPropertyName) -> [OpenGraphPropertyValue]? {
    let graphValue: OpenGraphPropertyValue? = self[key]
    return graphValue as? [OpenGraphPropertyValue]
  }

  subscript(key: OpenGraphPropertyName) -> Photo? {
    let graphValue: OpenGraphPropertyValue? = self[key]
    return graphValue as? Photo
  }

  subscript(key: OpenGraphPropertyName) -> URL? {
    let graphValue: OpenGraphPropertyValue? = self[key]
    return graphValue as? URL
  }
}
