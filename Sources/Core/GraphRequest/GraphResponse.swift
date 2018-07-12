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
 Represents a generic response that was received when `GraphRequest` succeeded.
 */
public struct GraphResponse: GraphResponseProtocol {
  private let rawResponse: Any?

  /**
   Initializes a `GraphResponse`.

   - parameter rawResponse: Raw response received from a server.
   Usually is represented by either a `Dictionary` or `Array`.
   */
  public init(rawResponse: Any?) {
    self.rawResponse = rawResponse
  }

  /**
   Converts and returns a response in a form of `Dictionary<String, Any>`.
   If the conversion fails or there is was response - returns `nil`.
   */
  public var dictionaryValue: [String: Any]? {
    return rawResponse as? [String: Any]
  }

  /**
   Converts and returns a response in a form of `Array<Any>`
   If the conversion fails or there is was response - returns `nil`.
   */
  public var arrayValue: [Any]? {
    return rawResponse as? [Any]
  }

  /**
   Converts and returns a response in a form of `String`.
   If the conversion fails or there is was response - returns `nil`.
   */
  public var stringValue: String? {
    return rawResponse as? String
  }
}
