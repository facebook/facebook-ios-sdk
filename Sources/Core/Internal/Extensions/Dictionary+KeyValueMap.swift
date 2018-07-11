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

extension Dictionary {
  func keyValueMap<K, V>(_ transform: (Element) throws -> (K, V)) rethrows -> [K: V] {
    var dictionary: [K: V] = [:]
    try forEach {
      let transformed = try transform($0)
      dictionary[transformed.0] = transformed.1
    }
    return dictionary
  }

  func keyValueFlatMap<K, V>(_ transform: (Element) throws -> (K?, V?)) rethrows -> [K: V] {
    var dictionary: [K: V] = [:]
    try forEach {
      let transformed = try transform($0)
      if let key = transformed.0,
        let value = transformed.1 {
        dictionary[key] = value
      }
    }
    return dictionary
  }
}
