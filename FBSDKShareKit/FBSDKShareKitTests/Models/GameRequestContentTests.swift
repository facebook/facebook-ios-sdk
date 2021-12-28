/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import FBSDKCoreKit
import XCTest

class GameRequestContentTests: XCTestCase {
  func testProperties() {
    let content = GameRequestContentTests.contentWithAllProperties()
    XCTAssertEqual(content.recipients, GameRequestContentTests.recipients())
    XCTAssertEqual(content.message, GameRequestContentTests.message())
    XCTAssertEqual(content.actionType, GameRequestContentTests.actionType())
    XCTAssertEqual(content.objectID, GameRequestContentTests.objectID())
    XCTAssertEqual(content.filters, GameRequestContentTests.filters())
    XCTAssertEqual(content.recipientSuggestions, GameRequestContentTests.recipientSuggestions())
    XCTAssertEqual(content.data, GameRequestContentTests.data())
    XCTAssertEqual(content.title, GameRequestContentTests.title())
  }

  func testCopy() {
    let content = GameRequestContentTests.contentWithAllProperties()
    let contentCopy = content.copy() as? GameRequestContent
    XCTAssertNotIdentical(contentCopy, content)
    XCTAssertEqual(contentCopy, content)
  }

  func testCoding() {
    let content = GameRequestContentTests.contentWithAllProperties()
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
      content: GameRequestContentTests.contentWithMinimalProperties()
    )
  }

  func testValidationWithManyProperties() {
    testValidationWithContent(
      content: GameRequestContentTests.contentWithManyProperties()
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
    let content = GameRequestContentTests.contentWithMinimalProperties()
    content.recipients = GameRequestContentTests.recipients()
    testValidationWithContent(content: content)
  }

  func testValidationWithActionTypeSend() {
    let content = GameRequestContentTests.contentWithMinimalProperties()
    content.actionType = .send
    testValidationWithContentAndErrorArgument(
      content: content,
      errorArgumentName: "objectID"
    )
  }

  func testValidationWithActionTypeSendAndobjectID() {
    let content = GameRequestContentTests.contentWithMinimalProperties()
    content.actionType = .send
    content.objectID = GameRequestContentTests.objectID()
    testValidationWithContent(content: content)
  }

  func testValidationWithActionTypeAskFor() {
    let content = GameRequestContentTests.contentWithMinimalProperties()
    content.actionType = .askFor
    testValidationWithContentAndErrorArgument(
      content: content,
      errorArgumentName: "objectID"
    )
  }

  func testValidationWithActionTypeAskForAndobjectID() {
    let content = GameRequestContentTests.contentWithMinimalProperties()
    content.actionType = .askFor
    content.objectID = GameRequestContentTests.objectID()
    testValidationWithContent(content: content)
  }

  func testValidationWithActionTypeTurn() {
    let content = GameRequestContentTests.contentWithMinimalProperties()
    content.actionType = .turn
    testValidationWithContent(content: content)
  }

  func testValidationWithActionTypeTurnAndobjectID() {
    let content = GameRequestContentTests.contentWithMinimalProperties()
    content.actionType = .turn
    content.objectID = GameRequestContentTests.objectID()
    testValidationWithContentAndErrorArgument(
      content: content,
      errorArgumentName: "objectID"
    )
  }

  func testValidationWithFilterAppUsers() {
    let content = GameRequestContentTests.contentWithMinimalProperties()
    content.filters = .appUsers
    testValidationWithContent(content: content)
  }

  func testValidationWithFilterAppNonUsers() {
    let content = GameRequestContentTests.contentWithMinimalProperties()
    content.filters = .appNonUsers
    testValidationWithContent(content: content)
  }

  func testValidationWithToAndFilters() {
    let content = GameRequestContentTests.contentWithMinimalProperties()
    content.filters = GameRequestContentTests.filters()
    content.recipients = GameRequestContentTests.recipients()
    testValidationWithContentAndErrorArgument(
      content: content,
      errorArgumentName: "recipients"
    )
  }

  func testValidationWithToAndSuggestions() {
    let content = GameRequestContentTests.contentWithMinimalProperties()
    content.recipients = GameRequestContentTests.recipients()
    content.recipientSuggestions = GameRequestContentTests.recipientSuggestions()
    testValidationWithContentAndErrorArgument(
      content: content,
      errorArgumentName: "recipients"
    )
  }

  func testValidationWithFiltersAndSuggestions() {
    let content = GameRequestContentTests.contentWithMinimalProperties()
    content.filters = GameRequestContentTests.filters()
    content.recipientSuggestions = GameRequestContentTests.recipientSuggestions()
    testValidationWithContentAndErrorArgument(
      content: content,
      errorArgumentName: "recipientSuggestions"
    )
  }

  func testValidationWithToAndFiltersAndSuggestions() {
    let content = GameRequestContentTests.contentWithMinimalProperties()
    content.filters = GameRequestContentTests.filters()
    content.recipients = GameRequestContentTests.recipients()
    content.recipientSuggestions = GameRequestContentTests.recipientSuggestions()
    testValidationWithContentAndErrorArgument(
      content: content,
      errorArgumentName: "recipients"
    )
  }

  func testValidationWithLongData() {
    let content = GameRequestContentTests.contentWithMinimalProperties()
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
