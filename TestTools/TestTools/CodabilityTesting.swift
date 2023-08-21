/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import Foundation

private struct DecodingError: Error {}

public enum CodabilityTesting {
  public static func encodeAndDecode<T: NSCoding & NSObject>(_ object: T) throws -> T {
    let encodedData = try NSKeyedArchiver.archivedData(withRootObject: object, requiringSecureCoding: false)
    guard let decodedObject = try NSKeyedUnarchiver.unarchivedObject(ofClass: T.self, from: encodedData) else {
      throw DecodingError()
    }
    return decodedObject
  }
}
