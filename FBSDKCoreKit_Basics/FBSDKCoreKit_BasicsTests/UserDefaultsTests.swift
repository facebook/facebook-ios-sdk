/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import FBSDKCoreKit_Basics
import XCTest

final class UserDefaultsTests: XCTestCase {

  // swiftlint:disable:next implicitly_unwrapped_optional
  var userDefaults: UserDefaults!

  override func setUp() {
    super.setUp()
    userDefaults = UserDefaults()
  }

  override func tearDown() {
    userDefaults.removeObject(forKey: .integerKey)
    userDefaults.removeObject(forKey: .stringKey)
    userDefaults.removeObject(forKey: .dataKey)
    userDefaults.removeObject(forKey: .objectKey)
    userDefaults = nil

    super.tearDown()
  }

  func testGettingInteger() {
    userDefaults.set(14, forKey: .integerKey)
    XCTAssertEqual(userDefaults.fb_integer(forKey: .integerKey), 14, .getInteger)
  }

  func testSettingInteger() {
    userDefaults.fb_setInteger(14, forKey: .integerKey)
    XCTAssertEqual(userDefaults.integer(forKey: .integerKey), 14, .setInteger)
  }

  func testGettingObject() {
    let object = NSString(string: "some value")
    userDefaults.set(object, forKey: .objectKey)

    XCTAssertIdentical(userDefaults.fb_object(forKey: .objectKey) as AnyObject, object, .getObject)
  }

  func testSettingObject() {
    let object = NSString(string: "some value")
    userDefaults.fb_setObject(object, forKey: .objectKey)

    XCTAssertIdentical(userDefaults.object(forKey: .objectKey) as AnyObject, object, .setObject)
  }

  func testGettingString() {
    userDefaults.set("some value", forKey: .stringKey)
    XCTAssertEqual(userDefaults.fb_string(forKey: .stringKey), "some value", .getString)
  }

  func testGettingData() {
    let data = Data(repeating: 14, count: 14)
    userDefaults.set(data, forKey: .dataKey)

    XCTAssertEqual(userDefaults.fb_data(forKey: .dataKey), data, .getData)
  }

  func testRemovingObject() {
    let object = NSString(string: "some value")
    userDefaults.set(object, forKey: .objectKey)

    userDefaults.fb_removeObject(forKey: .objectKey)
    XCTAssertNil(userDefaults.object(forKey: .objectKey), .removeObject)
  }
}

// MARK: - Assumptions

fileprivate extension String {
  static let getInteger = "User defaults can get an integer through an internal abstraction"
  static let setInteger = "User defaults can set an integer through an internal abstraction"
  static let getObject = "User defaults can get an object through an internal abstraction"
  static let setObject = "User defaults can set an object through an internal abstraction"
  static let getString = "User defaults can get a string through an internal abstraction"
  static let getData = "User defaults can get data through an internal abstraction"
  static let removeObject = "User defaults can remove an object through an internal abstraction"
}

// MARK: - Test Values

fileprivate extension String {
  static let integerKey = "integer"
  static let stringKey = "string"
  static let dataKey = "data"
  static let objectKey = "object"
}
