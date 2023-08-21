/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

@testable import FBSDKGamingServicesKit

import FBSDKCoreKit
import TestTools
import XCTest

// swiftlint:disable:next type_name
final class GameRequestFrictionlessRecipientCacheTests: XCTestCase {

  // swiftlint:disable implicitly_unwrapped_optional
  var cache: GameRequestFrictionlessRecipientCache!
  var graphRequestFactory: TestGraphRequestFactory!
  var notificationCenter: TestNotificationCenter!
  // swiftlint:enable implicitly_unwrapped_optional

  override func setUp() {
    super.setUp()

    graphRequestFactory = TestGraphRequestFactory()
    notificationCenter = TestNotificationCenter()
    cache = GameRequestFrictionlessRecipientCache()
    cache.setDependencies(
      .init(
        graphRequestFactory: graphRequestFactory,
        notificationCenter: notificationCenter,
        accessTokenWallet: TestAccessTokenWallet.self
      )
    )
  }

  override func tearDown() {
    cache = nil
    graphRequestFactory = nil
    notificationCenter = nil
    TestAccessTokenWallet.reset()

    super.tearDown()
  }

  // MARK: Dependencies

  func testCreatingWithDependencies() throws {
    let dependencies = try cache.getDependencies()

    XCTAssertIdentical(
      dependencies.graphRequestFactory,
      graphRequestFactory,
      "A recipient cache uses a provided graph request factory"
    )
    XCTAssertIdentical(
      dependencies.notificationCenter,
      notificationCenter,
      "A recipient cache uses the provided notification center"
    )
    XCTAssertIdentical(
      dependencies.accessTokenWallet,
      TestAccessTokenWallet.self,
      "A recipient cache uses the provided access token wallet"
    )
  }

  func testDefaultDependencies() throws {
    cache.resetDependencies()
    let dependencies = try cache.getDependencies()

    XCTAssertTrue(
      dependencies.graphRequestFactory is GraphRequestFactory,
      "A cache uses graph request factory for its graph request factory protocol by default"
    )
    XCTAssertIdentical(
      dependencies.notificationCenter,
      NotificationCenter.default,
      "A cache uses the default notification center for its notification delivering dependency by default"
    )
    XCTAssertIdentical(
      dependencies.accessTokenWallet,
      AccessToken.self,
      "A cache uses the AccessToken for its access token wallet dependency by default"
    )
  }

  // MARK: - Updating Cache

  func testUpdatingEmptyCacheWithoutAccessToken() {
    initiateFrictionlessRequest(usesValidAccessToken: false)

    XCTAssertNil(
      graphRequestFactory.capturedGraphPath,
      "Should not create a graph request without an access token"
    )
    XCTAssertTrue(cache.recipientIDs.isEmpty, "Should not update the recipient identifiers")
  }

  func testUpdatingCacheWithoutAccessToken() throws {
    _ = try seedRecipientIdentifiers()

    TestAccessTokenWallet.current = nil

    initiateFrictionlessRequest(usesValidAccessToken: false)

    XCTAssertTrue(
      cache.recipientIDs.isEmpty,
      "Should clear any cached identifiers when attempting to update without an access token"
    )
  }

  func testUpdatingCacheWithAccessToken() throws {
    initiateFrictionlessRequest()
    let request = try XCTUnwrap(graphRequestFactory.capturedRequests.first)

    XCTAssertEqual(
      request.graphPath,
      "me/apprequestformerrecipients",
      "Should create a graph request with the expected path"
    )
    XCTAssertEqual(
      request.parameters as? [String: String],
      ["fields": ""],
      "Should create a graph request with the expected parameters"
    )
    XCTAssertEqual(
      request.flags,
      [.doNotInvalidateTokenOnError, .disableErrorRecovery],
      "Should create a graph request with the expected flags"
    )

    XCTAssertEqual(
      request.startCallCount,
      1,
      "Should start the graph request"
    )
  }

  func testCompletingUpdateWithUniqueIdentifiers() throws {
    _ = try seedRecipientIdentifiers()

    XCTAssertEqual(
      cache.recipientIDs,
      Set(SampleData.validRecipientIDs),
      "Should set the recipient identifiers from the response"
    )
  }

  func testCompletingUpdateWithDuplicateIdentifiers() throws {
    initiateFrictionlessRequest()
    let request = try XCTUnwrap(graphRequestFactory.capturedRequests.first)
    let result = createValidResult(withRecipientIDs: SampleData.duplicateRecipientIDs)

    request.capturedCompletionHandler?(nil, result, nil)

    XCTAssertEqual(
      cache.recipientIDs,
      Set(SampleData.validRecipientIDs),
      "Should omit duplicate entries when setting the recipient identifiers from the response"
    )
  }

  func testCompletingUpdateWithEmptyListOfIdentifiers() throws {
    let request = try seedRecipientIdentifiers()

    // Call the completion again with an empty list
    request.capturedCompletionHandler?(nil, createValidResult(withRecipientIDs: []), nil)

    XCTAssertTrue(
      cache.recipientIDs.isEmpty,
      "Should overwrite the existing identifiers with whatever identifiers are in the response"
    )

    // Call the completion again with a non-empty list
    request.capturedCompletionHandler?(nil, createValidResult(), nil)

    XCTAssertFalse(
      cache.recipientIDs.isEmpty,
      "Should overwrite the existing identifiers with whatever identifiers are in the response"
    )
  }

  func testCompletingUpdateWithError() throws {
    let request = try seedRecipientIdentifiers()

    // Call the completion again with an error
    request.capturedCompletionHandler?(nil, nil, SampleError())

    XCTAssertFalse(
      cache.recipientIDs.isEmpty,
      "Should not clear the cache when receiving a server error"
    )
  }

  func testCompletingUpdateWithInvalidData() throws {
    let request = try seedRecipientIdentifiers()

    // Call the completion again with invalid data
    let result = ["data": "bad"]
    request.capturedCompletionHandler?(nil, result, nil)

    XCTAssertTrue(
      cache.recipientIDs.isEmpty,
      "Should clear the cached identifiers when receiving a bad result"
    )
  }

  func testUpdatingWithoutFrictionlessUpdates() throws {
    _ = try seedRecipientIdentifiers()

    cache.update(results: [:])

    XCTAssertEqual(
      cache.recipientIDs,
      Set(SampleData.validRecipientIDs),
      "Updating with empty results should not affect the cached recipient identifiers"
    )
  }

  // MARK: - Frictionless Recipient Checking

  func testRecipientsAreFrictionlessWithoutRecipients() throws {
    _ = try seedRecipientIdentifiers()

    XCTAssertFalse(cache.recipientsAreFrictionless(nil), "Missing recipients are not frictionless")
  }

  func testRecipientsAreFrictionlessWithStringArrayOfRecipients() throws {
    _ = try seedRecipientIdentifiers()

    XCTAssertFalse(
      cache.recipientsAreFrictionless(["cde", "456"]),
      "Recipients that are not cached are not frictionless"
    )
    XCTAssertTrue(
      cache.recipientsAreFrictionless(SampleData.validRecipientIDs),
      "Cached recipients are frictionless"
    )
  }

  func testRecipientsAreFrictionlessWithCommaSeparatedStringOfRecipients() throws {
    _ = try seedRecipientIdentifiers()

    XCTAssertFalse(
      cache.recipientsAreFrictionless("cde,456"),
      "Recipients that are not cached are not frictionless"
    )
    XCTAssertTrue(
      cache.recipientsAreFrictionless(
        SampleData.validRecipientIDs.joined(separator: ",")
      ),
      "Cached recipients are frictionless"
    )
  }

  func testRecipientsAreFrictionlessWithInvalidTypeOfRecipients() throws {
    _ = try seedRecipientIdentifiers()

    [
      true,
      false,
      1,
      Set(["foo"]),
      ["name": "123"],
    ]
      .forEach { value in
        XCTAssertFalse(cache.recipientsAreFrictionless(value))
      }
  }

  // MARK: - Notification Handling

  func testSubscribesToAccessTokenChangeNotifications() throws {
    let invocation = try XCTUnwrap(
      notificationCenter.capturedAddObserverInvocations.first,
      "A notification should be observed upon initialization"
    )

    XCTAssertEqual(
      invocation,
      .init(observer: nil, name: .AccessTokenDidChange, selector: nil, object: nil),
      "Should observe the correct notification upon initialization"
    )
  }

  func testReceivingNotificationThatAccessTokenChanged() throws {
    _ = try seedRecipientIdentifiers()

    let notification = Notification(
      name: .AccessTokenDidChange,
      object: nil,
      userInfo: [AccessTokenDidChangeUserIDKey: true]
    )
    notificationCenter.capturedCompletions.first?(notification)

    XCTAssertTrue(cache.recipientIDs.isEmpty, "A change in access token should clear the cache.")

    XCTAssertEqual(
      graphRequestFactory.capturedRequests.count,
      2,
      "A change in access token should prompt a new request"
    )
  }

  func testReceivingNotificationThatAccessTokenDidNotChange() throws {
    _ = try seedRecipientIdentifiers()

    let notification = Notification(
      name: .AccessTokenDidChange,
      object: nil,
      userInfo: [AccessTokenDidChangeUserIDKey: false]
    )
    notificationCenter.capturedCompletions.first?(notification)

    XCTAssertFalse(
      cache.recipientIDs.isEmpty,
      "A change in access token that does not change the user ID should not clear the cache."
    )

    XCTAssertEqual(
      graphRequestFactory.capturedRequests.count,
      1,
      "A change in access token that does not change the user ID should not prompt a new request"
    )
  }

  func testReceivingNotificationThatAccessTokenExpired() throws {
    _ = try seedRecipientIdentifiers()

    let notification = Notification(name: .AccessTokenDidChange, object: nil, userInfo: [AccessTokenDidExpireKey: true])
    notificationCenter.capturedCompletions.first?(notification)

    XCTAssertFalse(
      cache.recipientIDs.isEmpty,
      "A change in access token that does not change the user ID should not clear the cache."
    )

    XCTAssertEqual(
      graphRequestFactory.capturedRequests.count,
      1,
      "A change in access token that does not change the user ID should not prompt a new request"
    )
  }

  // MARK: - Helpers

  private enum SampleData {
    static var validRecipientIDs: [String] {
      ["abc", "123"]
    }

    static var duplicateRecipientIDs: [String] {
      validRecipientIDs + validRecipientIDs
    }
  }

  private func createValidResult(
    withRecipientIDs recipientIDs: [String]? = SampleData.validRecipientIDs
  ) -> [String: Any] {
    [
      "data": [
        "recipient_id": recipientIDs,
      ],
    ]
  }

  private func initiateFrictionlessRequest(usesValidAccessToken: Bool = true) {
    if usesValidAccessToken {
      TestAccessTokenWallet.stubbedCurrentAccessToken = SampleAccessTokens.validToken
    }

    cache.update(results: ["updated_frictionless": true])
  }

  /// Seeds valid recipient identifiers on the cache and returns the test graph request
  private func seedRecipientIdentifiers(
    _ file: StaticString = #file,
    _ line: UInt = #line
  ) throws -> TestGraphRequest {
    initiateFrictionlessRequest()
    let request = try XCTUnwrap(
      graphRequestFactory.capturedRequests.first,
      file: file,
      line: line
    )
    request.capturedCompletionHandler?(nil, createValidResult(), nil)
    XCTAssertFalse(
      cache.recipientIDs.isEmpty,
      "Should set valid identifiers",
      file: file,
      line: line
    )

    return request
  }
}
