/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !os(tvOS)

import Foundation

/// The protocol sdk dialogs must conform to and implement all the following methods.
@objc(FBSDKDialog)
public protocol DialogProtocol {
  /// The receiver's delegate or nil if it doesn't have a delegate.
  weak var delegate: ContextDialogDelegate? { get set }

  /// The content object used to create the specific dialog
  var dialogContent: ValidatableProtocol? { get set }

  /**
   Begins to show the specfic dialog
   @return true if the receiver was able to show the dialog, otherwise false.
   */
  func show() -> Bool

  /// Validates the content for the dialog
  func validate() throws
}

/// A protocol that a content object must conform to be used in a Gaming Services dialog
@objc(FBSDKValidatable)
public protocol ValidatableProtocol {

  func validate() throws
}

#endif
