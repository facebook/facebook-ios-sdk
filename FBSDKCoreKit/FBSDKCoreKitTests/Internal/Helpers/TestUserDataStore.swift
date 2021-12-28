/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import XCTest

@objcMembers
class TestUserDataStore: NSObject, UserDataPersisting {

  var wasGetUserDataCalled = false
  var wasClearUserDataCalled = false
  var capturedEmail: String?
  var capturedFirstName: String?
  var capturedLastName: String?
  var capturedPhone: String?
  var capturedDateOfBirth: String?
  var capturedGender: String?
  var capturedCity: String?
  var capturedState: String?
  var capturedZip: String?
  var capturedCountry: String?
  var capturedExternalId: String?
  var capturedSetUserDataForTypeData: String?
  var capturedSetUserDataForTypeType: FBSDKAppEventUserDataType?
  var capturedClearUserDataForTypeType: FBSDKAppEventUserDataType?
  var getInternalHashedDataForTypeCallCount = 0
  var capturedInternalHashedDataForTypeData: String?
  var capturedInternalHashedDataForTypeType: FBSDKAppEventUserDataType?
  var capturedEnableRules: [String]?

  func setUser( // swiftlint:disable:this function_parameter_count
    email: String?,
    firstName: String?,
    lastName: String?,
    phone: String?,
    dateOfBirth: String?,
    gender: String?,
    city: String?,
    state: String?,
    zip: String?,
    country: String?,
    externalId: String?
  ) {
    capturedEmail = email
    capturedFirstName = firstName
    capturedLastName = lastName
    capturedPhone = phone
    capturedDateOfBirth = dateOfBirth
    capturedGender = gender
    capturedCity = city
    capturedState = state
    capturedZip = zip
    capturedCountry = country
    capturedExternalId = externalId
  }

  func getUserData() -> String? {
    wasGetUserDataCalled = true
    return nil
  }

  func clearUserData() {
    wasClearUserDataCalled = true
  }

  func setUserData(_ data: String?, forType type: FBSDKAppEventUserDataType) {
    capturedSetUserDataForTypeData = data
    capturedSetUserDataForTypeType = type
  }

  func clearUserData(forType type: FBSDKAppEventUserDataType) {
    capturedClearUserDataForTypeType = type
  }

  func setEnabledRules(_ rules: [String]) {
    capturedEnableRules = rules
  }

  func getInternalHashedData(forType type: FBSDKAppEventUserDataType) -> String? {
    getInternalHashedDataForTypeCallCount += 1
    return nil
  }

  func setInternalHashData(_ hashData: String?, forType type: FBSDKAppEventUserDataType) {
    capturedInternalHashedDataForTypeData = hashData
    capturedInternalHashedDataForTypeType = type
  }
}
