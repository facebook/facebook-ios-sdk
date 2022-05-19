/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import FBSDKCoreKit

/**
 A dialog presenter responsible for creating and showing all the dialogs that create, switch,
 choose and otherwise manipulate the gaming context.
 */
@objcMembers
@objc(FBSDKContextDialogPresenter)
public final class ContextDialogPresenter: NSObject {

  private(set) var createContextDialogFactory: CreateContextDialogMaking
  private(set) var switchContextDialogFactory: SwitchContextDialogMaking
  private(set) var chooseContextDialogFactory: ChooseContextDialogMaking

  public override convenience init() {
    self.init(
      createContextDialogFactory: CreateContextDialogFactory(tokenProvider: AccessTokenProvider.self),
      switchContextDialogFactory: SwitchContextDialogFactory(tokenProvider: AccessTokenProvider.self),
      chooseContextDialogFactory: ChooseContextDialogFactory()
    )
  }

  init(
    createContextDialogFactory: CreateContextDialogMaking,
    switchContextDialogFactory: SwitchContextDialogMaking,
    chooseContextDialogFactory: ChooseContextDialogMaking
  ) {
    self.createContextDialogFactory = createContextDialogFactory
    self.switchContextDialogFactory = switchContextDialogFactory
    self.chooseContextDialogFactory = chooseContextDialogFactory

    super.init()
  }

  /**
   Convenience method to build up and show an instant games create context dialog with content and delegate.

   - Parameters:
      - content: The content for the create context dialog
      - delegate: The receiver's delegate.
   */
  public func makeAndShowCreateContextDialog(
    content: CreateContextContent,
    delegate: ContextDialogDelegate
  ) throws {
    guard let dialog = try createContextDialogFactory.makeCreateContextDialog(
      content: content,
      windowFinder: InternalUtility.shared,
      delegate: delegate
    )
    else {
      throw ContextDialogPresenterError.showCreateContext
    }

    _ = dialog.show()
  }

  /**
   Convenience method to build up and show an instant games switch context dialog with the giving content and delegate.

   - Parameters:
      - content: The content for the switch context dialog
      - delegate: The receiver's delegate.
   */
  public func makeAndShowSwitchContextDialog(
    content: SwitchContextContent,
    delegate: ContextDialogDelegate
  ) throws {
    guard let dialog = try switchContextDialogFactory.makeSwitchContextDialog(
      content: content,
      windowFinder: InternalUtility.shared,
      delegate: delegate
    )
    else {
      throw ContextDialogPresenterError.showSwitchContext
    }

    _ = dialog.show()
  }

  /**
   Convenience method to build up and show an instant games choose context dialog with content and a delegate.

   - Parameters:
      - content: The content for the choose context dialog
      - delegate: The receiver's delegate.
   */
  public func makeAndShowChooseContextDialog(
    content: ChooseContextContent,
    delegate: ContextDialogDelegate
  ) {
    _ = chooseContextDialogFactory.makeChooseContextDialog(
      content: content,
      delegate: delegate
    )
      .show()
  }
}
