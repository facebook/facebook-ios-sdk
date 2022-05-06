/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !os(tvOS)

import FBSDKCoreKit

/**
 A dialog for sharing content through Messenger.

 SUPPORTED SHARE TYPES
 - FBSDKShareLinkContent

 UNSUPPORTED SHARE TYPES (DEPRECATED AUGUST 2018)
 - FBSDKShareOpenGraphContent
 - FBSDKSharePhotoContent
 - FBSDKShareVideoContent
 - FBSDKShareMessengerOpenGraphMusicTemplateContent
 - FBSDKShareMessengerMediaTemplateContent
 - FBSDKShareMessengerGenericTemplateContent
 - Any other types that are not one of the four supported types listed above
 */
@objcMembers
@objc(FBSDKMessageDialog)
public class MessageDialog: NSObject, SharingDialog { // swiftlint:disable:this prefer_final_classes

  /// The receiver's delegate or nil if it doesn't have a delegate.
  public weak var delegate: SharingDelegate?

  /// The content to be shared.
  public var shareContent: SharingContent?

  /**
   A Boolean value that indicates whether the receiver should fail if it finds an error with the share content.

   If `false`, the sharer will still be displayed without the data that was mis-configured.  For example, an
   invalid placeID specified on the shareContent would produce a data error.
   */
  public var shouldFailOnDataError = false

  private let shareDialogConfiguration: ShareDialogConfigurationProtocol

  private static var hasCheckedCanOpenURLSchemeRegistered = false

  // This only exists so that `FBSendButton` can create a dialog without content during configuration
  override convenience init() {
    self.init(content: nil, delegate: nil)
  }

  /**
   Convenience initializer to return a Message Share Dialog with content and a delegate.
   @param content The content to be shared.
   @param delegate The receiver's delegate.
   */
  @objc(initWithContent:delegate:)
  public convenience init(content: SharingContent?, delegate: SharingDelegate?) {
    self.init(
      content: content,
      delegate: delegate,
      shareDialogConfiguration: ShareDialogConfiguration()
    )
  }

  init(
    content: SharingContent?,
    delegate: SharingDelegate?,
    shareDialogConfiguration: ShareDialogConfigurationProtocol
  ) {
    let internalUtility: InternalUtilityProtocol
    do {
      internalUtility = try Self.getDependencies().internalUtility
    } catch {
      fatalError(String(describing: error))
    }

    if !Self.hasCheckedCanOpenURLSchemeRegistered {
      Self.hasCheckedCanOpenURLSchemeRegistered = true
      internalUtility.checkRegisteredCanOpenURLScheme(URLScheme.messengerApp.rawValue)
    }

    shareContent = content
    self.delegate = delegate
    self.shareDialogConfiguration = shareDialogConfiguration

    super.init()
  }

  /**
   Convenience method to return a Message Share Dialog with content and a delegate.
   @param content The content to be shared.
   @param delegate The receiver's delegate.
   */
  @objc(dialogWithContent:delegate:)
  public static func dialog(content: SharingContent?, delegate: SharingDelegate?) -> MessageDialog {
    MessageDialog(content: content, delegate: delegate)
  }

  /**
   Convenience method to show a Message Share Dialog with content and a delegate.
   @param content The content to be shared.
   @param delegate The receiver's delegate.
   */
  @objc(showWithContent:delegate:)
  public static func show(content: SharingContent?, delegate: SharingDelegate?) -> MessageDialog {
    let dialog = MessageDialog(content: content, delegate: delegate)
    dialog.show()
    return dialog
  }

  /**
   A Boolean value that indicates whether the receiver can initiate a share.

   May return `false` if the appropriate Facebook app is not installed and is required or an access token is
   required but not available.  This method does not validate the content on the receiver, so this can be checked before
   building up the content.

   See `Sharing.validate()`
   @return `true` if the receiver can share, otherwise `false`.
   */
  public var canShow: Bool { canShowNative }

  /**
   Shows the dialog.
   @return `true` if the receiver was able to begin sharing, otherwise `false`.
   */
  @discardableResult
  public func show() -> Bool {
    guard let dependencies = try? Self.getDependencies() else { return false }

    guard canShow else {
      let error = dependencies.errorFactory.error(
        domain: ShareErrorDomain,
        code: ShareError.dialogNotAvailable.rawValue,
        userInfo: nil,
        message: "Message dialog is not available.",
        underlyingError: nil
      )

      invokeDelegateDidFail(error: error)
      return false
    }

    do {
      try validate()
    } catch {
      invokeDelegateDidFail(error: error)
      return false
    }

    var parameters = [String: Any]()

    if let content = shareContent {
      parameters = dependencies.shareUtility.bridgeParameters(
        for: content,
        options: [],
        shouldFailOnDataError: shouldFailOnDataError
      )
    }

    guard let request = dependencies.bridgeAPIRequestFactory.bridgeAPIRequest(
      with: .native,
      scheme: URLScheme.messengerApp.rawValue,
      methodName: ShareBridgeAPI.MethodName.share,
      parameters: parameters,
      userInfo: nil
    )
    else { return false }

    let shouldUseSafariViewController = shareDialogConfiguration
      .shouldUseSafariViewController(forDialogName: FBSDKDialogConfigurationNameMessage)

    dependencies.bridgeAPIRequestOpener.open(
      request,
      useSafariViewController: shouldUseSafariViewController,
      from: nil
    ) { response in
      self.handleCompletion(
        dialogResults: response.responseParameters ?? [:],
        response: response
      )
      dependencies.internalUtility.unregisterTransientObject(self)
    }

    logDialogShow()
    dependencies.internalUtility.registerTransientObject(self)

    return true
  }

  /**
   Validates the content on the receiver.
   @return `true` if the content is valid, otherwise `false`.
   */
  public func validate() throws {
    let dependencies = try Self.getDependencies()

    guard let content = shareContent else {
      let error = dependencies.errorFactory.requiredArgumentError(
        domain: ShareErrorDomain,
        name: "shareContent",
        message: nil,
        underlyingError: nil
      )
      throw error
    }

    let isContentSupported = (content is ShareLinkContent)
      || (content is SharePhotoContent)
      || (content is ShareVideoContent)

    guard isContentSupported else {
      let type = String(describing: type(of: content))
      let message = "Message dialog does not support \(type)."
      throw dependencies.errorFactory.requiredArgumentError(
        domain: ShareErrorDomain,
        name: "shareContent",
        message: message,
        underlyingError: nil
      )
    }

    try dependencies.shareUtility.validateShareContent(content, options: [])
  }

  private var canShowNative: Bool {
    guard let internalUtility = try? Self.getDependencies().internalUtility else {
      return false
    }

    let shouldUseNativeDialog = shareDialogConfiguration.shouldUseNativeDialog(
      forDialogName: FBSDKDialogConfigurationNameMessage
    )
    return shouldUseNativeDialog && internalUtility.isMessengerAppInstalled
  }

  func handleCompletion(dialogResults: [String: Any], response: BridgeAPIResponse) {
    let completionGesture = dialogResults[ShareBridgeAPI.CompletionGesture.key] as? String
    let isCancelGesture = (completionGesture == ShareBridgeAPI.CompletionGesture.cancelValue)
    if isCancelGesture || response.isCancelled {
      invokeDelegateDidCancel()
    } else if let error = response.error {
      invokeDelegateDidFail(error: error)
    } else {
      invokeDelegateDidComplete(results: dialogResults)
    }
  }

  private func invokeDelegateDidCancel() {
    let parameters: [AppEvents.ParameterName: Any] = [
      .outcome: ShareAppEventsParameters.DialogOutcomeValue.cancelled,
    ]

    let dependencies = try? Self.getDependencies()

    dependencies?.eventLogger.logInternalEvent(
      .messengerShareDialogResult,
      parameters: parameters,
      isImplicitlyLogged: true,
      accessToken: dependencies?.accessTokenWallet.current
    )

    delegate?.sharerDidCancel(self)
  }

  private func invokeDelegateDidComplete(results: [String: Any]) {
    let parameters: [AppEvents.ParameterName: Any] = [
      .outcome: ShareAppEventsParameters.DialogOutcomeValue.completed,
    ]

    let dependencies = try? Self.getDependencies()

    dependencies?.eventLogger.logInternalEvent(
      .messengerShareDialogResult,
      parameters: parameters,
      isImplicitlyLogged: true,
      accessToken: dependencies?.accessTokenWallet.current
    )

    delegate?.sharer(self, didCompleteWithResults: results)
  }

  private func invokeDelegateDidFail(error: Error) {
    let parameters: [AppEvents.ParameterName: Any] = [
      .outcome: ShareAppEventsParameters.DialogOutcomeValue.failed,
      .errorMessage: String(describing: error),
    ]

    let dependencies = try? Self.getDependencies()

    dependencies?.eventLogger.logInternalEvent(
      .shareDialogResult,
      parameters: parameters,
      isImplicitlyLogged: true,
      accessToken: dependencies?.accessTokenWallet.current
    )

    delegate?.sharer(self, didFailWithError: error)
  }

  private func logDialogShow() {
    let contentType: String
    switch shareContent {
    case is ShareLinkContent:
      contentType = ShareAppEventsParameters.ContentTypeValue.status
    case is SharePhotoContent:
      contentType = ShareAppEventsParameters.ContentTypeValue.photo
    case is ShareVideoContent:
      contentType = ShareAppEventsParameters.ContentTypeValue.video
    default:
      contentType = ShareAppEventsParameters.ContentTypeValue.unknown
    }

    var parameters: [AppEvents.ParameterName: Any] = [.shareContentType: contentType]

    if let uuid = shareContent?.shareUUID {
      parameters[.shareContentUUID] = uuid
    }

    if let pageID = shareContent?.pageID {
      parameters[.shareContentPageID] = pageID
    }

    guard let dependencies = try? Self.getDependencies() else { return }

    dependencies.eventLogger.logInternalEvent(
      .shareDialogShow,
      parameters: parameters,
      isImplicitlyLogged: true,
      accessToken: dependencies.accessTokenWallet.current
    )
  }
}

extension MessageDialog: DependentAsType {
  struct TypeDependencies {
    var accessTokenWallet: AccessTokenProviding.Type
    var bridgeAPIRequestFactory: BridgeAPIRequestCreating
    var bridgeAPIRequestOpener: BridgeAPIRequestOpening
    var errorFactory: ErrorCreating
    var eventLogger: ShareEventLogging
    var internalUtility: InternalUtilityProtocol & AppAvailabilityChecker
    var shareUtility: (ShareUtilityProtocol & ShareValidating).Type
  }

  static var defaultDependencies: TypeDependencies? = TypeDependencies(
    accessTokenWallet: AccessToken.self,
    bridgeAPIRequestFactory: ShareBridgeAPIRequestFactory(),
    bridgeAPIRequestOpener: BridgeAPI.shared,
    errorFactory: ErrorFactory(),
    eventLogger: AppEvents.shared,
    internalUtility: InternalUtility.shared,
    shareUtility: _ShareUtility.self
  )

  static var configuredDependencies: TypeDependencies?
}

#endif
