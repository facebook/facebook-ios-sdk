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
public class ContextDialogPresenter {

  private(set) var createContextDialogFactory: CreateContextDialogMaking
  private(set) var switchContextDialogFactory: SwitchContextDialogMaking
  private(set) var chooseContextDialogFactory: ChooseContextDialogMaking

  public init() {
    createContextDialogFactory = CreateContextDialogFactory(tokenProvider: AccessTokenProvider.self)
    switchContextDialogFactory = SwitchContextDialogFactory(tokenProvider: AccessTokenProvider.self)
    chooseContextDialogFactory = ChooseContextDialogFactory()
  }

  convenience init(
    createContextDialogFactory: CreateContextDialogMaking,
    switchContextDialogFactory: SwitchContextDialogMaking,
    chooseContextDialogFactory: ChooseContextDialogMaking
  ) {
    self.init()

    self.createContextDialogFactory = createContextDialogFactory
    self.switchContextDialogFactory = switchContextDialogFactory
    self.chooseContextDialogFactory = chooseContextDialogFactory
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
    guard let dialog = makeCreateContextDialog(content: content, delegate: delegate)
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
    guard let dialog = makeSwitchContextDialog(content: content, delegate: delegate)
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
    _ = makeChooseContextDialog(content: content, delegate: delegate)
      .show()
  }

  @available(*, deprecated, message: "showChooseContextDialog is deprecated. Please use the instance method `makeAndShowChooseContextDialog` instead") // swiftlint:disable:this line_length
  open class func showChooseContextDialog( // swiftlint:disable:this lower_acl_than_parent
    with content: ChooseContextContent,
    delegate: ContextDialogDelegate
  ) -> ChooseContextDialog {
    let dialog = ContextDialogPresenter().makeChooseContextDialog(content: content, delegate: delegate)
    _ = dialog.show()

    return dialog as? ChooseContextDialog ?? ChooseContextDialog(content: content, delegate: delegate)
  }

  // MARK: - Dialog factory methods

  func makeCreateContextDialog(
    content: CreateContextContent,
    delegate: ContextDialogDelegate
  ) -> Showable? {
    createContextDialogFactory.makeCreateContextDialog(
      content: content,
      windowFinder: InternalUtility.shared,
      delegate: delegate
    )
  }

  func makeSwitchContextDialog(
    content: SwitchContextContent,
    delegate: ContextDialogDelegate
  ) -> Showable? {
    switchContextDialogFactory.makeSwitchContextDialog(
      content: content,
      windowFinder: InternalUtility.shared,
      delegate: delegate
    )
  }

  func makeChooseContextDialog(
    content: ChooseContextContent,
    delegate: ContextDialogDelegate
  ) -> Showable {
    chooseContextDialogFactory.makeChooseContextDialog(
      content: content,
      delegate: delegate
    )
  }
}
