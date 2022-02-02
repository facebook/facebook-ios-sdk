/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import FBSDKCoreKit
import FBSDKCoreKit_Basics
import XCTest

final class MetadataIndexerTests: XCTestCase {
  var emailField = UITextField()
  var emailView = UITextView()
  var phoneField = UITextField()
  var phoneView = UITextView()
  var pwdField = UITextField()
  var pwdView = UITextView()
  var userDataStore = TestUserDataStore()
  lazy var metadataIndexer = MetadataIndexer(
    userDataStore: userDataStore,
    swizzler: TestSwizzler.self
  )

  let rules = [
    "r1": [
      "k": "email,e-mail,em,electronicmail",
      "v": "^([A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,})$",
    ],
    "r2": [
      "k": "phone,mobile,contact",
      "v": "^([0-9]{5,15})$",
    ],
    "r3": [
      "k": "gender,gen,sex",
      "v": "^(male|boy|man|female|girl|woman)$",
    ],
    "r4": [
      "k": "city",
      "v": "",
    ],
    "r5": [
      "k": "state,province",
      "v": "",
    ],
    "r6": [
      "k": "zip,zcode,pincode,pcode,postalcode,postcode",
      "v": "(^\\d{5}$)|(^\\d{9}$)|(^\\d{5}-\\d{4}$)",
    ],
    "r7": [
      "k": "firstname,first name,fn,fname,givenname,forename",
      "v": "",
    ],
    "r8": [
      "k": "lastname,last name,ln,lname,surname,sname,familyname",
      "v": "",
    ],
  ]

  override func setUp() {
    super.setUp()

    metadataIndexer.constructRules(rules)
    metadataIndexer.initStore()

    // clear store
    for key in rules {
      metadataIndexer.store[key] = []
    }

    emailField.placeholder = NSLocalizedString("Enter your email", comment: "")
    emailField.keyboardType = .emailAddress

    emailView.keyboardType = .emailAddress

    phoneField.placeholder = NSLocalizedString("Enter your phone", comment: "")
    phoneField.keyboardType = .phonePad

    pwdField.placeholder = NSLocalizedString("Enter your password", comment: "")
    pwdField.isSecureTextEntry = true

    pwdView.isSecureTextEntry = true
  }

  override func tearDown() {
    TestSwizzler.reset()

    super.tearDown()
  }

  func testCreatingWithDependencies() {
    XCTAssertEqual(
      metadataIndexer.userDataStore as? TestUserDataStore,
      userDataStore,
      "Should use the provided user data store"
    )
    XCTAssertTrue(
      metadataIndexer.swizzler == TestSwizzler.self,
      "Should use the provided swizzler"
    )
  }

  func testInitStore() {
    XCTAssertEqual(
      userDataStore.getInternalHashedDataForTypeCallCount,
      rules.count,
      "Should request the internal hashed data for each rule"
    )
  }

  func testSetupWithMissingRules() {
    metadataIndexer.setup(withRules: nil)

    XCTAssertNil(
      userDataStore.capturedEnableRules,
      "Should not invoke the user data store when there are missing rules"
    )
  }

  func testSetupWithEmptyRules() {
    metadataIndexer.setup(withRules: [:])

    XCTAssertNil(
      userDataStore.capturedEnableRules,
      "Should not invoke the user data store when there are empty rules"
    )
  }

  func testSetupWithRules() throws {
    metadataIndexer.setup(withRules: rules)

    let keys = Array(rules.keys)

    let capturedEnableRules = try XCTUnwrap(userDataStore.capturedEnableRules)
    XCTAssertEqual(keys.sorted(), capturedEnableRules.sorted())
  }

  func testCheckAndAppendDataForKeyWithUnknownKey() {
    metadataIndexer.checkAndAppendData(name, forKey: "foo")

    XCTAssertNil(
      userDataStore.capturedInternalHashedDataForTypeData,
      "Should not set data for a key that is not in the known rules"
    )
    XCTAssertNil(
      userDataStore.capturedInternalHashedDataForTypeType,
      "Should not set data for a key that is not in the known rules"
    )
  }

  func testCheckAndAppendDataForKeyWithKeyMatchingRule() {
    /* Assumes the indexer is set up with the rule:
     "r1": @{
       "k": "email,e-mail,em,electronicmail",
       "v": "^([A-Z0-9a-z._%+-]+[A-Za-z0-9.-]+\\.[A-Za-z]{2,})$",
     },
     */
    let expected = BasicUtility.sha256Hash(name as NSObject)
    metadataIndexer.checkAndAppendData(name, forKey: "r1")

    XCTAssertEqual(
      userDataStore.capturedInternalHashedDataForTypeData,
      expected,
      "Should hash and set the provided data"
    )
  }

  func testCheckAndAppendDataForKeyWithEmptyData() {
    metadataIndexer.checkAndAppendData("", forKey: "key")

    XCTAssertNil(
      userDataStore.capturedInternalHashedDataForTypeData,
      "Shouldn't set empty hashed data"
    )
  }

  // test for geting secure text entry in UITextField
  func testCheckSecureTextEntryOfTextField() {
    // without secure text
    XCTAssertFalse(
      metadataIndexer.checkSecureTextEntry(emailField),
      "test for UITextField without secure text"
    )

    // with secure text
    XCTAssertTrue(
      metadataIndexer.checkSecureTextEntry(pwdField),
      "test for UITextField with secure text"
    )
  }

  // test for geting secure text entry in UITextView
  func testCheckSecureTextEntryOfTextView() {
    // without secure text
    XCTAssertFalse(
      metadataIndexer.checkSecureTextEntry(emailView),
      "test for UITextView without secure text"
    )

    // with secure text
    XCTAssertTrue(
      metadataIndexer.checkSecureTextEntry(pwdView),
      "test for UITextView with secure text"
    )
  }

  // test for geting keyboard type from UITextField
  func testGetKeyboardTypeOfTextField() {
    XCTAssertEqual(
      emailField.keyboardType,
      metadataIndexer.getKeyboardType(emailField),
      "test for geting keyboard type from UITextField"
    )
  }

  // test for geting keyboard type from UITextView
  func testGetKeyboardTypeOfTextView() {
    XCTAssertEqual(
      emailView.keyboardType,
      metadataIndexer.getKeyboardType(emailView),
      "test for geting keyboard type from UITextView"
    )
  }

  // test for geting metadata with valid email
  func testGetMetadataWithEmail() {
    let text = "test@fb.com"
    metadataIndexer.getMetadataWithText(
      text,
      placeholder: "Enter your Email",
      labels: nil,
      secureTextEntry: false,
      inputType: .emailAddress
    )
    let r1Indexer = metadataIndexerStoredValue(forKey: "r1")
    let r2Indexer = metadataIndexerStoredValue(forKey: "r2")

    XCTAssertEqual(
      r1Indexer[0],
      Utility.sha256Hash(text as NSObject),
      "Getting metadata with a valid email should check rules related to emails."
    )
    XCTAssertEqual(
      r2Indexer.count,
      0,
      "Getting metadata with a valid email should not check rules related to phone numbers."
    )
  }

  // test for geting metadata with valid phone number
  func testGetMetadataWithPhoneNumber() {
    let text = "1112223333"
    metadataIndexer.getMetadataWithText(
      text,
      placeholder: "Enter your Phone Number",
      labels: nil,
      secureTextEntry: false,
      inputType: .phonePad
    )
    let r1Indexer = metadataIndexerStoredValue(forKey: "r1")
    let r2Indexer = metadataIndexerStoredValue(forKey: "r2")
    XCTAssertEqual(
      r2Indexer[0],
      Utility.sha256Hash(text as NSObject),
      "Getting metadata with a valid phone number should check rules related to phone numbers."
    )
    XCTAssertEqual(
      r1Indexer.count,
      0,
      "Getting metadata with a valid phone number should not check rules related to emails."
    )
  }

  // test for geting metadata with valid phone number or zipcode with labels
  func testGetMetadataWithPhoneNumberWithLabels() {
    let text = "11122"
    metadataIndexer.getMetadataWithText(
      text,
      placeholder: "",
      labels: ["phone", "zipcode"],
      secureTextEntry: false,
      inputType: .phonePad
    )
    let r2Indexer = metadataIndexerStoredValue(forKey: "r2")
    let r6Indexer = metadataIndexerStoredValue(forKey: "r6")
    XCTAssertEqual(
      r2Indexer[0],
      Utility.sha256Hash(text as NSObject),
      "Getting metadata with a phone number or zipcode with label should check rules related to phone numbers."
    )
    XCTAssertEqual(
      r6Indexer[0],
      Utility.sha256Hash(text as NSObject),
      "Getting metadata with a phone number or zipcode with label should check rules related to zipcodes."
    )
  }

  // test for geting metadata with secure text
  func testGetMetadataWithSecureText() {
    let text = "dfjald1314"
    metadataIndexer.getMetadataWithText(
      text,
      placeholder: "Enter your Pass-word",
      labels: nil,
      secureTextEntry: true,
      inputType: .default
    )
    let r1Indexer = metadataIndexerStoredValue(forKey: "r1")
    let r2Indexer = metadataIndexerStoredValue(forKey: "r2")

    XCTAssertEqual(
      r1Indexer.count,
      0,
      "Getting metadata with a secret text should not check rules related to emails."
    )
    XCTAssertEqual(
      r2Indexer.count,
      0,
      "Getting metadata with a secret text should not check rules related to phone numbers."
    )
  }

  // test for geting metadata with invalid email
  func testGetMetadataWithInvalidEmail() {
    let text = "test"
    metadataIndexer.getMetadataWithText(
      text,
      placeholder: "Enter your Email",
      labels: nil,
      secureTextEntry: false,
      inputType: .emailAddress
    )
    let r1Indexer = metadataIndexerStoredValue(forKey: "r1")
    let r2Indexer = metadataIndexerStoredValue(forKey: "r2")

    XCTAssertEqual(
      r1Indexer.count,
      0,
      "Getting metadata with an invalid email should not check rules related to emails."
    )
    XCTAssertEqual(
      r2Indexer.count,
      0,
      "Getting metadata with an invalid email should not check rules related to phone numbers."
    )
  }

  // test for geting metadata with invalid email placeholder
  func testGetMetadataWithInvalidEmailPlaceholder() {
    let text = "test@fb.com"
    metadataIndexer.getMetadataWithText(
      text,
      placeholder: "Enter your",
      labels: nil,
      secureTextEntry: false,
      inputType: .emailAddress
    )
    let r1Indexer = metadataIndexerStoredValue(forKey: "r1")
    let r2Indexer = metadataIndexerStoredValue(forKey: "r2")

    XCTAssertEqual(
      r1Indexer.count,
      0,
      "Getting metadata with an invalid email placeholder should not check rules related to emails."
    )
    XCTAssertEqual(
      r2Indexer.count,
      0,
      "Getting metadata with an invalid email placeholder should not check rules related to phone numbers."
    )
  }

  // test for getting metadata with valid phone number containing +-().
  func testGetMetadataWithValidPhoneNumberWithPunctuations() throws {
    let text = "+1(222)-333-444"
    metadataIndexer.getMetadataWithText(
      text,
      placeholder: "Enter your Phone Number",
      labels: nil,
      secureTextEntry: false,
      inputType: .phonePad
    )
    let r2Indexer = metadataIndexerStoredValue(forKey: "r2")
    let numberNoPunctuations = try XCTUnwrap(Utility.sha256Hash("1222333444" as NSObject))
    let numberWithPunctuations = try XCTUnwrap(Utility.sha256Hash(text as NSObject))
    XCTAssertTrue(
      r2Indexer.contains(numberNoPunctuations),
      "Getting metadata with a phone number with punctuations should check rules related to phone numbers with pure numbers." // swiftlint:disable:this line_length
    )
    XCTAssertFalse(
      r2Indexer.contains(numberWithPunctuations),
      "Getting metadata with a phone number with punctuations should not check rules related to phone numbers with the original text." // swiftlint:disable:this line_length
    )
  }

  // test for geting metadata with invalid phone number
  func testGetMetadataWithInvalidPhoneNumber() {
    metadataIndexer.getMetadataWithText(
      "1234",
      placeholder: "Enter your Phone Number",
      labels: nil,
      secureTextEntry: false,
      inputType: .phonePad
    )

    metadataIndexer.getMetadataWithText(
      "1234567891011121314",
      placeholder: "Mobile Number",
      labels: nil,
      secureTextEntry: false,
      inputType: .phonePad
    )
    let r2Indexer = metadataIndexerStoredValue(forKey: "r2")
    XCTAssertEqual(
      r2Indexer.count,
      0,
      "Getting metadata with an invalid phone number should not check rules related to phone numbers."
    )
  }

  // test for geting metadata with invalid phone number placeholder
  func testGetMetadataWithInvalidPhoneNumberPlaceholder() {
    let text = "1112223333"
    metadataIndexer.getMetadataWithText(
      text,
      placeholder: "Enter your",
      labels: nil,
      secureTextEntry: false,
      inputType: .phonePad
    )
    let r1Indexer = metadataIndexerStoredValue(forKey: "r1")
    let r2Indexer = metadataIndexerStoredValue(forKey: "r2")
    XCTAssertEqual(
      r1Indexer.count,
      0,
      "Getting metadata with an invalid phone number placeholder should not check rules related to emails."
    )
    XCTAssertEqual(
      r2Indexer.count,
      0,
      "Getting metadata with an invalid phone number placeholder should not check rules related to phone numbers."
    )
  }

  // test for geting metadata with text which is neither email nor phone number
  func testGetMetadataWithTextNotEmailAndPhone() {
    let text = "facebook"
    metadataIndexer.getMetadataWithText(
      text,
      placeholder: "Enter your Name",
      labels: nil,
      secureTextEntry: false,
      inputType: .alphabet
    )
    let r1Indexer = metadataIndexerStoredValue(forKey: "r1")
    let r2Indexer = metadataIndexerStoredValue(forKey: "r2")
    XCTAssertEqual(
      r1Indexer.count,
      0,
      "Getting metadata with a plain text (not email nor phone number) should not check rules related to emails."
    )
    XCTAssertEqual(
      r2Indexer.count,
      0,
      "Getting metadata with a plain text (not email nor phone number) should not check rules related to phone numbers."
    )
  }

  // test for geting metadata with no text
  func testGetMetadataWithNoText() {
    let text = ""
    metadataIndexer.getMetadataWithText(
      text,
      placeholder: "Enter your Email",
      labels: nil,
      secureTextEntry: false,
      inputType: .emailAddress
    )
    let r1Indexer = metadataIndexerStoredValue(forKey: "r1")
    let r2Indexer = metadataIndexerStoredValue(forKey: "r2")
    XCTAssertEqual(
      r1Indexer.count,
      0,
      "Getting metadata with an empty string should not check rules related to emails."
    )
    XCTAssertEqual(
      r2Indexer.count,
      0,
      "Getting metadata with an empty string should not check rules related to phone numbers."
    )
  }

  // test for geting metadata with too long text
  func testGetMetadataWithTooLongText() {
    let text = "".padding(toLength: 1000, withPad: "a", startingAt: 0) + "@fb.com"
    metadataIndexer.getMetadataWithText(
      text,
      placeholder: "Enter your Email",
      labels: nil,
      secureTextEntry: false,
      inputType: .emailAddress
    )
    let r1Indexer = metadataIndexerStoredValue(forKey: "r1")

    let r2Indexer = metadataIndexerStoredValue(forKey: "r2")
    XCTAssertEqual(
      r1Indexer.count,
      0,
      "Getting metadata with a too long text should not check rules related to emails."
    )
    XCTAssertEqual(
      r2Indexer.count,
      0,
      "Getting metadata with a too long text should not check rules related to phone numbers."
    )
  }

  // test for geting metadata with too long placeholder
  func testGetMetadataWithTooLongPlaceholder() {
    let text = "test@fb.com"
    let indicator = "".padding(toLength: 1000, withPad: "enter your email ", startingAt: 0)
    metadataIndexer.getMetadataWithText(
      text,
      placeholder: indicator,
      labels: nil,
      secureTextEntry: false,
      inputType: .emailAddress
    )
    let r1Indexer = metadataIndexerStoredValue(forKey: "r1")
    let r2Indexer = metadataIndexerStoredValue(forKey: "r2")

    XCTAssertEqual(
      r1Indexer.count,
      0,
      "Getting metadata with a too long placeholder should not check rules related to emails."
    )
    XCTAssertEqual(
      r2Indexer.count,
      0,
      "Getting metadata with a too long placeholder should not check rules related to phone numbers."
    )
  }

  // test for getting metadata with gender
  func testGetMetadataWithValidGender() {
    let text = "male"
    let indicator = "gender"
    metadataIndexer.getMetadataWithText(
      text,
      placeholder: indicator,
      labels: nil,
      secureTextEntry: false,
      inputType: .default
    )
    let r3Indexer = metadataIndexerStoredValue(forKey: "r3")
    XCTAssertEqual(
      r3Indexer[0],
      Utility.sha256Hash("m" as NSObject),
      "Getting metadata with a valid gender should check rules related genders."
    )
  }

  func testGetMetadataWithInvalidGender() {
    let text = "test"
    let indicator = "gender"
    metadataIndexer.getMetadataWithText(
      text,
      placeholder: indicator,
      labels: nil,
      secureTextEntry: false,
      inputType: .default
    )
    let r3Indexer = metadataIndexerStoredValue(forKey: "r3")
    XCTAssertEqual(
      r3Indexer.count,
      0,
      "Getting metadata with an invalid gender should not check rules related to genders."
    )
  }

  func testGetMetadataWithInvalidGenderIndicator() {
    let text = "female"
    let indicator = "test"
    metadataIndexer.getMetadataWithText(
      text,
      placeholder: indicator,
      labels: nil,
      secureTextEntry: false,
      inputType: .default
    )
    let r3Indexer = metadataIndexerStoredValue(forKey: "r3")
    XCTAssertEqual(
      r3Indexer.count,
      0,
      "Getting metadata with an invalid gender indicator should not check rules related to genders."
    )
  }

  // test for getting meta with city
  func testGetMetadataWithValidCity() {
    let text = "Menlo Park"
    let indicator = "city"
    metadataIndexer.getMetadataWithText(
      text,
      placeholder: indicator,
      labels: nil,
      secureTextEntry: false,
      inputType: .default
    )
    let r4Indexer = metadataIndexerStoredValue(forKey: "r4")
    XCTAssertEqual(
      r4Indexer[0],
      Utility.sha256Hash("menlopark" as NSObject),
      "Getting metadata with a valid city name should check rules related cities."
    )
  }

  func testGetMetadataWithInvalidCity() {
    // Although rule_V for city is "", but should not accept empty text case
    let text = ""
    let indicator = "city"
    metadataIndexer.getMetadataWithText(
      text,
      placeholder: indicator,
      labels: nil,
      secureTextEntry: false,
      inputType: .default
    )
    let r4Indexer = metadataIndexerStoredValue(forKey: "r4")

    XCTAssertEqual(
      r4Indexer.count,
      0,
      "Getting metadata with an invalid city name should not check rules related to cities."
    )
  }

  func testGetMetadataWithInvalidCityIndicator() {
    let text = "Menlo Park"
    let indicator = "test"
    metadataIndexer.getMetadataWithText(
      text,
      placeholder: indicator,
      labels: nil,
      secureTextEntry: false,
      inputType: .default
    )
    let r4Indexer = metadataIndexerStoredValue(forKey: "r4")

    XCTAssertEqual(
      r4Indexer.count,
      0,
      "Getting metadata with an invalid city indicator should not check rules related to cities."
    )
  }

  // test for getting meta with state
  func testGetMetadataWithValidState() {
    let text = "CA"
    let indicator = "province"
    metadataIndexer.getMetadataWithText(
      text,
      placeholder: indicator,
      labels: nil,
      secureTextEntry: false,
      inputType: .default
    )
    let r5Indexer = metadataIndexerStoredValue(forKey: "r5")

    XCTAssertEqual(
      r5Indexer[0],
      Utility.sha256Hash("ca" as NSObject),
      "Getting metadata with a valid state/province name should check rules related to states."
    )
  }

  func testGetMetadataWithInvalidState() {
    // Although rule_V for state is "", but should not accept empty text case
    let text = ""
    let indicator = "state"
    metadataIndexer.getMetadataWithText(
      text,
      placeholder: indicator,
      labels: nil,
      secureTextEntry: false,
      inputType: .default
    )
    let r5Indexer = metadataIndexerStoredValue(forKey: "r5")

    XCTAssertEqual(
      r5Indexer.count,
      0,
      "Getting metadata with an invalid state/province name should not check rules related to states."
    )
  }

  func testGetMetadataWithInvalidStateIndicator() {
    let text = "CA"
    let indicator = "test"
    metadataIndexer.getMetadataWithText(
      text,
      placeholder: indicator,
      labels: nil,
      secureTextEntry: false,
      inputType: .default
    )
    let r5Indexer = metadataIndexerStoredValue(forKey: "r5")
    XCTAssertEqual(
      r5Indexer.count,
      0,
      "Getting metadata with an invalid state/province indicator should not check rules related to states."
    )
  }

  // test for getting meta with zip
  func testGetMetadataWithValidZip() {
    let text = "94025"
    let indicator = "zcode"
    metadataIndexer.getMetadataWithText(
      text,
      placeholder: indicator,
      labels: nil,
      secureTextEntry: false,
      inputType: .default
    )
    let r6Indexer = metadataIndexerStoredValue(forKey: "r6")
    XCTAssertEqual(
      r6Indexer[0],
      Utility.sha256Hash(text as NSObject),
      "Getting metadata with a valid zipcode should check rules related to zipcodes."
    )
  }

  // test for getting metadata with valid zipcode containing "-" (will also be regarded as phone number)
  func testGetMetadataWithValidZipWithPunctuations() throws {
    let text = "94025-1234"
    metadataIndexer.getMetadataWithText(
      text,
      placeholder: "",
      labels: ["zcode", "phone"],
      secureTextEntry: false,
      inputType: .phonePad
    )
    let r6Indexer = metadataIndexerStoredValue(forKey: "r6")
    let r2Indexer = metadataIndexerStoredValue(forKey: "r2")
    let validZipWithPunctuations = try XCTUnwrap(Utility.sha256Hash(text as NSObject))
    XCTAssertEqual(
      r6Indexer[0],
      Utility.sha256Hash("94025" as NSObject),
      "Getting metadata with a valid zipcode with punctuations should check rules related to zipcodes."
    )
    XCTAssertEqual(
      r2Indexer[0],
      Utility.sha256Hash("940251234" as NSObject),
      "Getting metadata with a valid zipcode with punctuations should check rules related to phone numbers." // swiftlint:disable:this line_length
    )
    XCTAssertFalse(
      r6Indexer.contains(validZipWithPunctuations),
      "Getting metadata with a valid zipcode with punctuations should not check rules related related to zipcodes with original text." // swiftlint:disable:this line_length
    )
  }

  func testGetMetadataWithInvalidZip() {
    // the rule for zip code should be 5-digit number
    let text = "9402"
    let indicator = "zcode"
    metadataIndexer.getMetadataWithText(
      text,
      placeholder: indicator,
      labels: nil,
      secureTextEntry: false,
      inputType: .default
    )
    let r6Indexer = metadataIndexerStoredValue(forKey: "r6")
    XCTAssertEqual(
      r6Indexer.count,
      0,
      "Getting metadata with an invalid zipcode should not check rules related to zipcodes."
    )
  }

  func testGetMetadataWithInvalidZipIndicator() {
    let text = "94025"
    let indicator = "test"
    metadataIndexer.getMetadataWithText(
      text,
      placeholder: indicator,
      labels: nil,
      secureTextEntry: false,
      inputType: .default
    )
    let r6Indexer = metadataIndexerStoredValue(forKey: "r6")
    XCTAssertEqual(
      r6Indexer.count,
      0,
      "Getting metadata with an invalid zipcode indicator should not check rules related to zipcodes."
    )
  }

  // test for getting meta with first name
  func testGetMetadataWithValidFn() {
    let text = "David"
    let indicator = "fn"
    metadataIndexer.getMetadataWithText(
      text,
      placeholder: indicator,
      labels: nil,
      secureTextEntry: false,
      inputType: .default
    )
    let r7Indexer = metadataIndexerStoredValue(forKey: "r7")
    XCTAssertEqual(
      r7Indexer[0],
      Utility.sha256Hash("david" as NSObject),
      "Getting metadata with a valid first name should check rules related to first names."
    )
  }

  func testGetMetadataWithInvalidFn() {
    // Although rule_V for first name is "", but should not accept empty text case
    let text = ""
    let indicator = "fn"
    metadataIndexer.getMetadataWithText(
      text,
      placeholder: indicator,
      labels: nil,
      secureTextEntry: false,
      inputType: .default
    )
    let r7Indexer = metadataIndexerStoredValue(forKey: "r7")
    XCTAssertEqual(
      r7Indexer.count,
      0,
      "Getting metadata with an empty string should check rules related to first names."
    )
  }

  func testGetMetadataWithInvalidFnIndicator() {
    let text = "David"
    let indicator = "test"
    metadataIndexer.getMetadataWithText(
      text,
      placeholder: indicator,
      labels: nil,
      secureTextEntry: false,
      inputType: .default
    )
    let r7Indexer = metadataIndexerStoredValue(forKey: "r7")
    XCTAssertEqual(
      r7Indexer.count,
      0,
      "Getting metadata with an invalid first name indicator should check rules related to first names."
    )
  }

  // test for getting meta with last name
  func testGetMetadataWithValidLn() {
    let text = "Taylor"
    let indicator = "ln"
    metadataIndexer.getMetadataWithText(
      text,
      placeholder: indicator,
      labels: nil,
      secureTextEntry: false,
      inputType: .default
    )
    let r8Indexer = metadataIndexerStoredValue(forKey: "r8")
    XCTAssertEqual(
      r8Indexer[0],
      Utility.sha256Hash("taylor" as NSObject),
      "Getting metadata with a valid last name should check rules related to last names."
    )
  }

  func testGetMetadataWithInvalidLn() {
    // Although rule_V for last name is "", but should not accept empty text case
    let text = ""
    let indicator = "ln"
    metadataIndexer.getMetadataWithText(
      text,
      placeholder: indicator,
      labels: nil,
      secureTextEntry: false,
      inputType: .default
    )
    let r8Indexer = metadataIndexerStoredValue(forKey: "r8")
    XCTAssertEqual(
      r8Indexer.count,
      0,
      "Getting metadata with an invalid last name should check rules related to last names."
    )
  }

  func testGetMetadataWithInvalidLnIndicator() {
    let text = "Taylor"
    let indicator = "test"
    metadataIndexer.getMetadataWithText(
      text,
      placeholder: indicator,
      labels: nil,
      secureTextEntry: false,
      inputType: .default
    )
    let r8Indexer = metadataIndexerStoredValue(forKey: "r8")
    XCTAssertEqual(
      r8Indexer.count,
      0,
      "Getting metadata with an invalid last name indicator should check rules related to last names."
    )
  }

  // test for getting meta with first name with labels (will also be regarded as last name, state, city
  func testGetMetadataWithFirstNameWithLabels() throws {
    let text = "Taylor"
    metadataIndexer.getMetadataWithText(
      text,
      placeholder: "",
      labels: ["fn", "ln", "state", "city"],
      secureTextEntry: false,
      inputType: .default
    )
    let r4Indexer = metadataIndexerStoredValue(forKey: "r4")
    let r5Indexer = metadataIndexerStoredValue(forKey: "r5")
    let r7Indexer = metadataIndexerStoredValue(forKey: "r7")
    let r8Indexer = metadataIndexerStoredValue(forKey: "r8")

    let cityLabel = try XCTUnwrap(Utility.sha256Hash("taylor" as NSObject))
    let stateLabel = try XCTUnwrap(Utility.sha256Hash("taylor" as NSObject))
    let fnLabel = try XCTUnwrap(Utility.sha256Hash("taylor" as NSObject))
    let lnLabel = try XCTUnwrap(Utility.sha256Hash("taylor" as NSObject))

    XCTAssertTrue(
      r4Indexer.contains(cityLabel),
      "Getting metadata with a first name with city label should check rules related to cities."
    )
    XCTAssertTrue(
      r5Indexer.contains(stateLabel),
      "Getting metadata with a first name with state label should check rules related to states."
    )
    XCTAssertTrue(
      r7Indexer.contains(fnLabel),
      "Getting metadata with a first name with fn label should check rules related to first names."
    )
    XCTAssertTrue(
      r8Indexer.contains(lnLabel),
      "Getting metadata with a first name with ln label should check rules related to last names."
    )
  }

  func metadataIndexerStoredValue(forKey key: String) -> [String] {
    metadataIndexer.store[key] as! [String] // swiftlint:disable:this force_cast
  }
}
