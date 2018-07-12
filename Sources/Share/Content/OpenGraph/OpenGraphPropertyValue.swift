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
import Foundation

/**
 A generic protocol for holding any value that can be represented as a property value in OpenGraph.
 */
public protocol OpenGraphPropertyValue {
  /// The bridged OpenGraph raw value.
  var openGraphPropertyValue: Any { get }
}

internal enum OpenGraphPropertyValueConverter {
  internal static func valueFrom(openGraphObjectValue value: Any) -> OpenGraphPropertyValue? {
    switch value {
    case let value as String: return value
    case let value as NSNumber: return value
    case let value as NSArray: return value.compactMap { valueFrom(openGraphObjectValue: $0 as Any) }
    case let value as URL: return value
    case let value as FBSDKSharePhoto: return Photo(sdkPhoto: value)
    case let value as FBSDKShareOpenGraphObject: return OpenGraphObject(sdkGraphObject: value)
    default:
      print("Recieved unknown OpenGraph value \(value)")
      return nil
    }
  }
}

extension NSNumber: OpenGraphPropertyValue {
  /// The bridged OpenGraph raw value.
  public var openGraphPropertyValue: Any {
    return self
  }
}

extension String: OpenGraphPropertyValue {
  /// The bridged OpenGraph raw value.
  public var openGraphPropertyValue: Any {
    return self
  }
}

extension Array: OpenGraphPropertyValue {
  /// The bridged OpenGraph raw value.
  public var openGraphPropertyValue: Any {
    return self
      .compactMap { $0 as? OpenGraphPropertyValue }
      .map { $0.openGraphPropertyValue }
  }
}

extension URL: OpenGraphPropertyValue {
  /// The bridged OpenGraph raw value.
  public var openGraphPropertyValue: Any {
    return self
  }
}

extension Photo: OpenGraphPropertyValue {
  /// The bridged OpenGraph raw value.
  public var openGraphPropertyValue: Any {
    return sdkPhotoRepresentation
  }
}

extension OpenGraphObject: OpenGraphPropertyValue {
  /// The bridged OpenGraph raw value.
  public var openGraphPropertyValue: Any {
    return sdkGraphObjectRepresentation
  }
}
