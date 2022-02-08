/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import FBSDKCoreKit
import FBSDKGamingServicesKit
import XCTest

final class GameRequestContentTests: XCTestCase {
  func testProperties() {
    let content = Self.contentWithAllProperties()
    XCTAssertEqual(content.recipients, Self.recipients())
    XCTAssertEqual(content.message, Self.message())
    XCTAssertEqual(content.actionType, Self.actionType())
    XCTAssertEqual(content.objectID, Self.objectID())
    XCTAssertEqual(content.filters, Self.filters())
    XCTAssertEqual(content.recipientSuggestions, Self.recipientSuggestions())
    XCTAssertEqual(content.data, Self.data())
    XCTAssertEqual(content.title, Self.title())
  }

  func testEquatabilityOfCopy() {
    let content = Self.contentWithAllProperties()
    let contentCopy = Self.contentWithAllProperties()
    XCTAssertNotIdentical(contentCopy, content)
    XCTAssertEqual(contentCopy, content)
  }

  func testCoding() {
    let content = Self.contentWithAllProperties()
    let data = NSKeyedArchiver.archivedData(withRootObject: content)
    let unarchiver = NSKeyedUnarchiver(forReadingWith: data)
    unarchiver.requiresSecureCoding = true
    let unarchivedObject = unarchiver.decodeObject(
      of: GameRequestContent.self,
      forKey: NSKeyedArchiveRootObjectKey
    )
    XCTAssertEqual(unarchivedObject, content)
  }

  func testValidationWithMinimalProperties() {
    testValidationWithContent(
      content: Self.contentWithMinimalProperties()
    )
  }

  func testValidationWithManyProperties() {
    testValidationWithContent(
      content: Self.contentWithManyProperties()
    )
  }

  func testValidationWithNoProperties() {
    let content = GameRequestContent()
    testValidationWithContentAndErrorArgument(
      content: content,
      errorArgumentName: "message"
    )
  }

  func testValidationWithTo() {
    let content = Self.contentWithMinimalProperties()
    content.recipients = Self.recipients()
    testValidationWithContent(content: content)
  }

  func testValidationWithActionTypeSend() {
    let content = Self.contentWithMinimalProperties()
    content.actionType = .send
    testValidationWithContentAndErrorArgument(
      content: content,
      errorArgumentName: "objectID"
    )
  }

  func testValidationWithActionTypeSendAndobjectID() {
    let content = Self.contentWithMinimalProperties()
    content.actionType = .send
    content.objectID = Self.objectID()
    testValidationWithContent(content: content)
  }

  func testValidationWithActionTypeAskFor() {
    let content = Self.contentWithMinimalProperties()
    content.actionType = .askFor
    testValidationWithContentAndErrorArgument(
      content: content,
      errorArgumentName: "objectID"
    )
  }

  func testValidationWithActionTypeAskForAndobjectID() {
    let content = Self.contentWithMinimalProperties()
    content.actionType = .askFor
    content.objectID = Self.objectID()
    testValidationWithContent(content: content)
  }

  func testValidationWithActionTypeTurn() {
    let content = Self.contentWithMinimalProperties()
    content.actionType = .turn
    testValidationWithContent(content: content)
  }

  func testValidationWithActionTypeTurnAndobjectID() {
    let content = Self.contentWithMinimalProperties()
    content.actionType = .turn
    content.objectID = Self.objectID()
    testValidationWithContentAndErrorArgument(
      content: content,
      errorArgumentName: "objectID"
    )
  }

  func testValidationWithFilterAppUsers() {
    let content = Self.contentWithMinimalProperties()
    content.filters = .appUsers
    testValidationWithContent(content: content)
  }

  func testValidationWithFilterAppNonUsers() {
    let content = Self.contentWithMinimalProperties()
    content.filters = .appNonUsers
    testValidationWithContent(content: content)
  }

  func testValidationWithToAndFilters() {
    let content = Self.contentWithMinimalProperties()
    content.filters = Self.filters()
    content.recipients = Self.recipients()
    testValidationWithContentAndErrorArgument(
      content: content,
      errorArgumentName: "recipients"
    )
  }

  func testValidationWithToAndSuggestions() {
    let content = Self.contentWithMinimalProperties()
    content.recipients = Self.recipients()
    content.recipientSuggestions = Self.recipientSuggestions()
    testValidationWithContentAndErrorArgument(
      content: content,
      errorArgumentName: "recipients"
    )
  }

  func testValidationWithFiltersAndSuggestions() {
    let content = Self.contentWithMinimalProperties()
    content.filters = Self.filters()
    content.recipientSuggestions = Self.recipientSuggestions()
    testValidationWithContentAndErrorArgument(
      content: content,
      errorArgumentName: "recipientSuggestions"
    )
  }

  func testValidationWithToAndFiltersAndSuggestions() {
    let content = Self.contentWithMinimalProperties()
    content.filters = Self.filters()
    content.recipients = Self.recipients()
    content.recipientSuggestions = Self.recipientSuggestions()
    testValidationWithContentAndErrorArgument(
      content: content,
      errorArgumentName: "recipients"
    )
  }

  func testValidationWithLongData() {
    let content = Self.contentWithMinimalProperties()
    content.data = String(format: "%.254f", 1)
    testValidationWithContentAndErrorArgument(
      content: content,
      errorArgumentName: "data"
    )
  }

  func testValidationWithContent(
    content: GameRequestContent,
    file: String = #file,
    line: UInt = #line
  ) {
    XCTAssertNoThrow(try content.validate(options: []))
  }

  func testValidationWithContentAndErrorArgument(
    content: GameRequestContent,
    errorArgumentName: String,
    file: String = #file,
    line: UInt = #line
  ) {
    var catchBlockHit = false
    do {
      try content.validate(options: [])
      XCTFail("Expecting Error to be Thrown")
    } catch {
      XCTAssertEqual((error as NSError).userInfo[ErrorArgumentNameKey] as? String, errorArgumentName)
      catchBlockHit = true
    }

    XCTAssertTrue(catchBlockHit)
  }

  private static func contentWithMinimalProperties() -> GameRequestContent {
    let content = GameRequestContent()
    content.message = message()
    return content
  }

  private static func contentWithAllProperties() -> GameRequestContent {
    let content = GameRequestContent()
    content.actionType = actionType()
    content.data = data()
    content.filters = filters()
    content.message = message()
    content.objectID = objectID()
    content.recipientSuggestions = recipientSuggestions()
    content.title = title()
    content.recipients = recipients()
    return content
  }

  private static func contentWithManyProperties() -> GameRequestContent {
    let content = GameRequestContent()
    content.data = data()
    content.message = message()
    content.title = title()
    return content
  }

  private static func recipients() -> [String] {
    ["recipient-id-1", "recipient-id-2"]
  }

  private static func message() -> String {
    "Here is an awesome item for you!"
  }

  private static func actionType() -> GameRequestActionType {
    .send
  }

  private static func objectID() -> String {
    "id-of-an-awesome-item"
  }

  private static func filters() -> GameRequestFilter {
    .appUsers
  }

  private static func recipientSuggestions() -> [String] {
    ["suggested-recipient-id-1", "suggested-recipient-id-2"]
  }

  private static func data() -> String {
    "some-data-highly-important"
  }

  private static func title() -> String {
    "Send this awesome item to your friends!"
  }
}
