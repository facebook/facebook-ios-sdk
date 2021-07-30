// Copyright (c) 2014-present, Facebook, Inc. All rights reserved.
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

#if FBSDK_SWIFT_PACKAGE
import FacebookCore
#else
import FBSDKCoreKit
#endif

import LegacyGamingServices

/**
  A dialog presenter responsible for creating and showing all the dialogs that create, switch,
 choose and otherwise manipulate the gaming context.
 */
public class ContextDialogPresenter {

  private(set) var createContextDialogFactory: CreateContextDialogMaking
  private(set) var switchContextDialogFactory: SwitchContextDialogMaking
  private(set) var chooseContextDialogFactory: ChooseContextDialogMaking

  public init() {
    self.createContextDialogFactory = CreateContextDialogFactory(tokenProvider: AccessTokenProvider.self)
    self.switchContextDialogFactory = SwitchContextDialogFactory(tokenProvider: AccessTokenProvider.self)
    self.chooseContextDialogFactory = ChooseContextDialogFactory()
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
  // swiftlint:enable line_length

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

    dialog.show()
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

    dialog.show()
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
    makeChooseContextDialog(content: content, delegate: delegate)
      .show()
  }

  @available(*, deprecated, message: "showChooseContextDialog is deprecated. Please use the instance method `makeAndShowChooseContextDialog` instead") // swiftlint:disable:this line_length
  open class func showChooseContextDialog( // swiftlint:disable:this lower_acl_than_parent
    with content: ChooseContextContent,
    delegate: ContextDialogDelegate
  ) -> ChooseContextDialog {
    let dialog = ContextDialogPresenter().makeChooseContextDialog(content: content, delegate: delegate)
    dialog.show()

    return dialog as? ChooseContextDialog ?? ChooseContextDialog(content: content, delegate: delegate)
  }

  // MARK: - Dialog factory methods

  func makeCreateContextDialog(
    content: CreateContextContent,
    delegate: ContextDialogDelegate
  ) -> Showable? {
    createContextDialogFactory.makeCreateContextDialog(
      with: content,
      windowFinder: InternalUtility.shared,
      delegate: delegate
    )
  }

  func makeSwitchContextDialog(
    content: SwitchContextContent,
    delegate: ContextDialogDelegate
  ) -> Showable? {
    switchContextDialogFactory.makeSwitchContextDialog(
      with: content,
      windowFinder: InternalUtility.shared,
      delegate: delegate
    )
  }

  func makeChooseContextDialog(
    content: ChooseContextContent,
    delegate: ContextDialogDelegate
  ) -> Showable {
    chooseContextDialogFactory.makeChooseContextDialog(
      with: content,
      delegate: delegate
    )
  }
}
