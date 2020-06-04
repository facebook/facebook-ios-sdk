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

@objc
public class Fuzzer: NSObject {

  private static let values: [Any] = [
    // Booleans
    true,
    false,
    // Numbers
    1,
    0,
    -1,
    Int.max,
    Double.greatestFiniteMagnitude,
    Float.greatestFiniteMagnitude,
    Double.leastNonzeroMagnitude,
    Double.leastNormalMagnitude,
    // Strings
    "1",
    "a",
    " ",
    "{}",
    "[]",
    "{",
    "}",
    "[ { \"something\": nonexistent } ]",
    "\\{ \"foo\": \"bar\" \\}",
    // Data
    Data(),
    "Foo".data(using: .utf8) ?? Data(),
    Data(count: 100),

    //swiftlint:disable force_try
    try! JSONSerialization.data(withJSONObject: ["foo": "bar"], options: .fragmentsAllowed),
    //swiftlint:enable force_try
    // Special Characters
    "\\",
    // Arrays
    [],
    [1, 2, 3],
    [1, 2, 3, "a", "b", "c"],
    (0 ... 100),
    ("a" ..< "z"),
    // Dictionaries
    "[:]",
    [:],
    ["Foo": "Bar"],
    ["": [1, 2, 3]],
    ["Foo": true],
    ["Foo": ["Bar": "Baz"]],
    ["Foo": ["a", 1, [:]]]
  ]

  @objc
  public class var random: Any {
    return values.randomElement() ?? values[0]
  }

  /// Randomizes the values of a JSON object
  /// Will not replace keys. Will either change their values or trim them entirely.
  /// Will be called recursively on dictionaries and arrays
  @objc
  public class func randomize(json: Any) -> Any {
    if var dictionary = json as? [String: Any] {
      return randomizeInPlace(json: &dictionary)
    }
    else if var array = json as? [Any] {
      return randomizeInPlace(array: &array)
    }
    else {
      return json
    }
  }

  private class func randomizeInPlace(array: inout [Any]) -> [Any] {
    var array = array

    array.enumerated().forEach { enumeration in
      if var dictionary = enumeration.element as? [String: Any] {
        array[enumeration.offset] = Bool.random() ? dictionary : randomizeInPlace(json: &dictionary)
      } else if let subarray = enumeration.element as? [Any] {
        array[enumeration.offset] = Bool.random() ? subarray : randomizeInPlace(array: &array)
      } else {
        array[enumeration.offset] = Bool.random() ? enumeration.element : random
      }
    }

    return array
  }

  private class func randomizeInPlace(json: inout [String: Any]) -> [String: Any] {
    json.keys.forEach { key in
      if var value = json[key] as? [String: Any] {
        json[key] = Bool.random() ? random : randomizeInPlace(json: &value)
      }
        // randomize array values if they are dictionaries
      else if var values = json[key] as? [Any] {
        json[key] = Bool.random() ? values : randomizeInPlace(array: &values)
      }
      else {
        if Bool.random() {
          json[key] = random
        }
      }
    }

    return json
  }
}
