/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import Foundation

@objcMembers
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

    // swiftlint:disable:next force_try
    try! JSONSerialization.data(withJSONObject: ["foo": "bar"], options: .fragmentsAllowed),
    // swiftlint:enable force_try
    // Special Characters
    "\\",
    // Arrays
    [],
    [1, 2, 3],
    [1, 2, 3, "a", "b", "c"],
    0 ... 100,
    "a" ..< "z",
    // Dictionaries
    "[:]",
    [:],
    ["Foo": "Bar"],
    ["": [1, 2, 3]],
    ["Foo": true],
    ["Foo": ["Bar": "Baz"]],
    ["Foo": ["a", 1, [:]]]
  ]

  public class var random: AnyObject {
    values.randomElement() as AnyObject
  }

  /// Randomizes the values of a JSON object
  /// Will not replace keys. Will either change their values or trim them entirely.
  /// Will be called recursively on dictionaries and arrays
  public class func randomize(json: Any) -> Any {
    if var dictionary = json as? [String: Any] {
      return randomizeInPlace(json: &dictionary)
    } else if var array = json as? [Any] {
      return randomizeInPlace(array: &array)
    } else {
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
      } else {
        if Bool.random() {
          json[key] = random
        } else if Bool.random() {
          json.removeValue(forKey: key)
        }
      }
    }

    return json
  }
}
