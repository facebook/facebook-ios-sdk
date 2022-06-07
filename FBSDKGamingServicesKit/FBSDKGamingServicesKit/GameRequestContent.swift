/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !os(tvOS)

import FBSDKCoreKit
import FBSDKShareKit
import Foundation

/// A model for a game request.
@objcMembers
@objc(FBSDKGameRequestContent)
public final class GameRequestContent: NSObject, SharingValidatable, NSSecureCoding {

  /**
   Used when defining additional context about the nature of the request.

   The parameter 'objectID' is required if the action type is either
   '.send' or '.askFor'.

   - SeeAlso: objectID
   */
  public var actionType = GameRequestActionType.none

  /**
   Additional freeform data you may pass for tracking. This will be stored as part of
   the request objects created. The maximum length is 255 characters.
   */
  public var data: String?

  /**
   This controls the set of friends someone sees if a multi-friend selector is shown.
   It is `.none` by default, meaning that all friends can be shown.
   If specify as `.appUsers`, only friends who use the app will be shown.
   On the other hands, use `.appNonUsers` to filter only friends who do not use the app.

   The parameter name is preserved to be consistent with the counter part on desktop.
   */
  public var filters = GameRequestFilter.none

  /**
   A plain-text message to be sent as part of the request. This text will surface in the App Center view
   of the request, but not on the notification jewel. Required parameter.
   */
  public var message = ""

  /**
   The Open Graph object ID of the object being sent.

   - SeeAlso: actionType
   */
  public var objectID = ""

  /**
   An array of user IDs, usernames or invite tokens (NSString) of people to send request.

   These may or may not be a friend of the sender. If this is specified by the app,
   the sender will not have a choice of recipients. If not, the sender will see a multi-friend selector

   This is equivalent to the "to" parameter when using the web game request dialog.
   */
  public var recipients = [String]()

  /**
   An array of user IDs that will be included in the dialog as the first suggested friends.
   Cannot be used together with filters.

   This is equivalent to the `suggestions` parameter when using the web game request dialog.
   */
  public var recipientSuggestions = [String]()

  /// The title for the dialog.
  public var title = ""

  /// The call to action for the dialog.
  public var cta = ""

  @objc(validateWithOptions:error:)
  public func validate(options: ShareBridgeOptions = []) throws {
    try _ShareUtility.validateRequiredValue(message, named: "message")

    let errorFactory = ErrorFactory()
    let mustHaveObjectID = (actionType == .send) || (actionType == .askFor)
    let hasObjectID = !objectID.isEmpty

    guard mustHaveObjectID == hasObjectID else {
      throw errorFactory.requiredArgumentError(
        domain: ShareErrorDomain,
        name: "objectID",
        message: "The objectID is required when the actionType is either .send or .askfor",
        underlyingError: nil
      )
    }

    let hasRecipients = !recipients.isEmpty
    let hasFilters = (filters != .none)
    let hasSuggestions = !recipientSuggestions.isEmpty

    guard !(hasRecipients && hasFilters) else {
      throw errorFactory.invalidArgumentError(
        domain: ShareErrorDomain,
        name: "recipients",
        value: recipients,
        message: "Cannot specify recipients and filters at the same time.",
        underlyingError: nil
      )
    }

    guard !(hasRecipients && hasSuggestions) else {
      throw errorFactory.invalidArgumentError(
        domain: ShareErrorDomain,
        name: "recipients",
        value: recipients,
        message: "Cannot specify recipients and suggestions at the same time.",
        underlyingError: nil
      )
    }

    guard !(hasFilters && hasSuggestions) else {
      throw errorFactory.invalidArgumentError(
        domain: ShareErrorDomain,
        name: "recipientSuggestions",
        value: recipientSuggestions,
        message: "Cannot specify filters and suggestions at the same time.",
        underlyingError: nil
      )
    }

    guard (data?.count ?? 0) <= 255 else {
      throw errorFactory.invalidArgumentError(
        domain: ShareErrorDomain,
        name: "data",
        value: data,
        message: "The data cannot be longer than 255 characters",
        underlyingError: nil
      )
    }

    try _ShareUtility.validateArgument(
      actionType,
      named: "actionType",
      in: [.none, .send, .askFor, .turn, .invite]
    )

    try _ShareUtility.validateArgument(
      filters,
      named: "filters",
      in: [.none, .appUsers, .appNonUsers, .everybody]
    )
  }

  public override func isEqual(_ object: Any?) -> Bool {
    guard let other = object as? GameRequestContent else { return false }

    return (self === other) || isEqual(to: other)
  }

  /**
   Compares the receiver to another game request content.
   @param content The other content
   @return `true` if the receiver's values are equal to the other content's values; otherwise `false`
   */
  @objc(isEqualToGameRequestContent:)
  public func isEqual(to content: GameRequestContent) -> Bool {
    actionType == content.actionType
      && filters == content.filters
      && data == content.data
      && message == content.message
      && objectID == content.objectID
      && recipientSuggestions == content.recipientSuggestions
      && title == content.title
      && recipients == content.recipients
  }

  private enum CodingKeys: String, CodingKey {
    case to
    case message
    case actionType
    case objectID
    case filters
    case suggestions
    case data
    case title
  }

  public class var supportsSecureCoding: Bool { true }

  public convenience init(coder decoder: NSCoder) {
    self.init()

    actionType = GameRequestActionType(
      rawValue: UInt(decoder.decodeInteger(forKey: CodingKeys.actionType.rawValue))
    ) ?? .none
    data = decoder.decodeObject(of: NSString.self, forKey: CodingKeys.data.rawValue) as String?
    filters = GameRequestFilter(rawValue: UInt(decoder.decodeInteger(forKey: CodingKeys.filters.rawValue))) ?? .none
    message = (decoder.decodeObject(of: NSString.self, forKey: CodingKeys.message.rawValue) as String?) ?? ""
    objectID = (decoder.decodeObject(of: NSString.self, forKey: CodingKeys.objectID.rawValue) as String?) ?? ""
    recipientSuggestions = (decoder.decodeObject(
      of: [NSArray.self, NSString.self],
      forKey: CodingKeys.suggestions.rawValue
    ) as? [String]) ?? []
    title = (decoder.decodeObject(of: NSString.self, forKey: CodingKeys.title.rawValue) as String?) ?? ""
    recipients = (decoder.decodeObject(
      of: [NSArray.self, NSString.self],
      forKey: CodingKeys.to.rawValue
    ) as? [String]) ?? []
  }

  public func encode(with encoder: NSCoder) {
    encoder.encode(Int(actionType.rawValue), forKey: CodingKeys.actionType.rawValue)
    encoder.encode(data, forKey: CodingKeys.data.rawValue)
    encoder.encode(Int(filters.rawValue), forKey: CodingKeys.filters.rawValue)
    encoder.encode(message, forKey: CodingKeys.message.rawValue)
    encoder.encode(objectID, forKey: CodingKeys.objectID.rawValue)
    encoder.encode(recipientSuggestions, forKey: CodingKeys.suggestions.rawValue)
    encoder.encode(title, forKey: CodingKeys.title.rawValue)
    encoder.encode(recipients, forKey: CodingKeys.to.rawValue)
  }
}

#endif
