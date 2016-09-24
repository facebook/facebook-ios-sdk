// Copyright (c) 2016-present, Facebook, Inc. All rights reserved.
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

import FBSDKShareKit

/**
 A model for a game request.
 */
public struct GameRequest {
  /**
   Used when defining additional context about the nature of the request.
   */
  public var actionType: ActionType?

  /**
   Additional freeform data you may pass for tracking. This will be stored as part of the request objects created.
   Maximum length is 255 characters.
   */
  public var data: String?

  /**
   This controls the set of friends someone sees if a multi-friend selector is shown.
   It is `.Default` by default, meaning that all friends can be shown.
   If specified as `HideUsers`, only friends who don't use the app will be shown.
   If specified as `HideNonUsers`, only friends who do use the app will be shown.
   */
  public var recipientsFilter: RecipientsFilter

  /**
   A plain-text message to be sent as part of the request.

   This text will surface in the App Center view of the request, but not on the notification jewel.
   */
  public var message: String

  /// The title for the dialog.
  public var title: String

  /**
   A set of user IDs, usernames or invite tokens of people to send the request to.

   These may or may not be a friend of the sender. If this is specified by the app, the sender will not have a choice
   of recipients. If not, the sender will see a multi-friend selector.
   */
  public var recipients: Set<Recipient>?

  /**
   An array of user IDs that will be included in the dialog as the first suggested friends.
   */
  public var recipientSuggestions: Set<Recipient>?

  /**
   Create a new game request content with a title and a message.

   - parameter title:   The title for the dialog.
   - parameter message: The message to be sent as part of the request.
   */
  public init(title: String, message: String) {
    self.title = title
    self.message = message
    self.recipientsFilter = .none
  }
}

extension GameRequest: Equatable {
  /**
   Compare two `GameRequest`s for equality.

   - parameter lhs: The first request to compare.
   - parameter rhs: The second request to compare.

   - returns: Whether or not the requests are equal.
   */
  public static func == (lhs: GameRequest, rhs: GameRequest) -> Bool {
    return lhs.sdkContentRepresentation == rhs.sdkContentRepresentation
  }
}

extension GameRequest {
  internal var sdkContentRepresentation: FBSDKGameRequestContent {
    let sdkContent = FBSDKGameRequestContent()
    let sdkActionRepresentation = actionType?.sdkActionRepresentation ?? (.none, nil)
    sdkContent.actionType = sdkActionRepresentation.0
    sdkContent.objectID = sdkActionRepresentation.1
    sdkContent.data = data
    sdkContent.filters = recipientsFilter.sdkFilterRepresentation
    sdkContent.title = title
    sdkContent.message = message
    sdkContent.recipients = recipients?.map { $0.rawValue }
    sdkContent.recipientSuggestions = recipientSuggestions?.map { $0.rawValue }
    return sdkContent
  }
}
