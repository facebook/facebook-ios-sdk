// Copyright (c) 2014-present, Facebook, Inc. All rights reserved.
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

enum SampleGraphResponses {
  case empty
  case nonJSON
  case utf8String
  case dictionary

  var unserialized: Any? {
    switch self {
    case .empty, .nonJSON:
      return nil

    case .utf8String:
      return "top level type"

    case .dictionary:
      return ["name": "bob"]
    }
  }

  var data: Data {
    switch self {
    case .empty:
      return Data()

    case .nonJSON:
      return withUnsafeBytes(of: 100.0) { Data($0) }

    case .utf8String:
      return (unserialized as! String).data(using: .utf8)! // swiftlint:disable:this force_cast force_unwrapping

    case .dictionary:
      return try! JSONSerialization.data(  // swiftlint:disable:this force_try
        withJSONObject: unserialized as Any,
        options: []
      )
    }
  }
}
