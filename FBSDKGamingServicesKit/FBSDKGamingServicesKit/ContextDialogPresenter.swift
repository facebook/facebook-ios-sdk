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
  @objc(showCreateContextDialogWithContent:delegate:)
  @available(*, deprecated, message: "This method is deprecated and will be removed in the next major release. Use the instance method `makeAndShowCreateContextDialog(content:delegate:)` instead") // swiftlint:disable:this line_length
  public class func showCreateContextDialog(
    withContent content: CreateContextContent,
    delegate: ContextDialogDelegate
  ) -> NSError? {
    do {
      try Self().makeAndShowCreateContextDialog(
        content: content,
        delegate: delegate
      )
      return nil
    } catch {
      return ErrorFactory().error(
        code: CoreError.errorAccessTokenRequired.rawValue,
        userInfo: nil,
        message: "A valid access token is required to launch the Dialog",
        underlyingError: nil
      ) as NSError
    }
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
    guard let dialog = try makeCreateContextDialog(content: content, delegate: delegate)
    else {
      throw ContextDialogPresenterError.showCreateContext
    }

    _ = dialog.show()
  }

  /**
   Convenience method to build up and show an instant games switch context dialog with content and delegate.

   - Parameters:
     - content: The content for the switch context dialog
     - delegate: The receiver's delegate.
   */
  @available(*, deprecated, message: "This method is deprecated and will be removed in the next major release. Use the instance method `makeAndShowSwitchContextDialog(content:delegate:)` instead") // swiftlint:disable:this line_length
  @objc(showSwitchContextDialogWithContent:delegate:)
  public class func showSwitchContextDialog(
    withContent content: SwitchContextContent,
    delegate: ContextDialogDelegate?
  ) -> NSError? {
    guard let delegate = delegate else { return nil }

    do {
      try Self().makeAndShowSwitchContextDialog(
        content: content,
        delegate: delegate
      )
      return nil
    } catch {
      return ErrorFactory().error(
        code: CoreError.errorAccessTokenRequired.rawValue,
        userInfo: nil,
        message: "A valid access token is required to launch the Dialog",
        underlyingError: nil
      ) as NSError
    }
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
    guard let dialog = try makeSwitchContextDialog(content: content, delegate: delegate)
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
  @available(*, deprecated, message: "This method is deprecated and will be removed in the next major release. Use the instance method `makeAndShowChooseContextDialog(content:delegate:)` instead") // swiftlint:disable:this line_length
  @objc(showChooseContextDialogWithContent:delegate:)
  @discardableResult
  public class func showChooseContextDialog(
    withContent content: ChooseContextContent,
    delegate: ContextDialogDelegate
  ) -> ChooseContextDialog {
    guard let dialog = Self().makeChooseContextDialog(content: content, delegate: delegate) as? ChooseContextDialog
    else {
      fatalError("Invalid dialog type created")
    }

    _ = dialog.show()
    return dialog
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
  public class func showChooseContextDialog(
    with content: ChooseContextContent,
    delegate: ContextDialogDelegate
  ) -> ChooseContextDialog {
    let dialog = ContextDialogPresenter().makeChooseContextDialog(content: content, delegate: delegate)
    _ = dialog.show()

    return dialog as? ChooseContextDialog ?? ChooseContextDialog(content: content, delegate: delegate)
  }

  // MARK: - Dialog factory methods

  /**
   Convenience method to build up an instant games create context dialog with content and delegate.

   - Parameters
     - content: The content for the create context dialog
     - delegate: The receiver's delegate.
   */
  @available(*, deprecated, message: "This method is deprecated and will be removed in the next major release. Use the instance method `makeAndShowCreateContextDialog(content:delegate:)` instead") // swiftlint:disable:this line_length
  @objc(createContextDialogWithContent:delegate:)
  public class func createContextDialog(
    withContent content: CreateContextContent,
    delegate: ContextDialogDelegate?
  ) -> CreateContextDialog? {
    guard let delegate = delegate else { return nil }

    return try? Self().makeCreateContextDialog(content: content, delegate: delegate) as? CreateContextDialog
  }

  func makeCreateContextDialog(
    content: CreateContextContent,
    delegate: ContextDialogDelegate
  ) throws -> Showable? {
    try createContextDialogFactory.makeCreateContextDialog(
      content: content,
      windowFinder: InternalUtility.shared,
      delegate: delegate
    )
  }

  /**
   Convenience method to build up an instant games switch context dialog with content and delegate.

   - Parameters:
     - content: The content for the switch context dialog
     - delegate: The receiver's delegate.
   */
  @available(*, deprecated, message: "This method is deprecated and will be removed in the next major release. Use the instance method `makeAndShowSwitchContextDialog(content:delegate:)` instead") // swiftlint:disable:this line_length
  @objc(switchContextDialogWithContent:delegate:)
  public class func switchContextDialog(
    withContent content: SwitchContextContent,
    delegate: ContextDialogDelegate?
  ) -> SwitchContextDialog? {
    guard let delegate = delegate else { return nil }

    return try? Self().makeSwitchContextDialog(content: content, delegate: delegate) as? SwitchContextDialog
  }

  func makeSwitchContextDialog(
    content: SwitchContextContent,
    delegate: ContextDialogDelegate
  ) throws -> Showable? {
    try switchContextDialogFactory.makeSwitchContextDialog(
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
