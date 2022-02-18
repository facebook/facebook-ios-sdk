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
public final class MessageDialog: NSObject, SharingDialog {

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

  private let appAvailabilityChecker: AppAvailabilityChecker
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
      appAvailabilityChecker: InternalUtility.shared,
      shareDialogConfiguration: ShareDialogConfiguration()
    )
  }

  init(
    content: SharingContent?,
    delegate: SharingDelegate?,
    appAvailabilityChecker: AppAvailabilityChecker,
    shareDialogConfiguration: ShareDialogConfigurationProtocol
  ) {
    if !Self.hasCheckedCanOpenURLSchemeRegistered {
      Self.hasCheckedCanOpenURLSchemeRegistered = true
      InternalUtility.shared.checkRegisteredCanOpenURLScheme(URLScheme.messengerApp.rawValue)
    }

    shareContent = content
    self.delegate = delegate
    self.appAvailabilityChecker = appAvailabilityChecker
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
    guard canShow else {
      let error = ErrorFactory().error(
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
      parameters = _ShareUtility.bridgeParameters(
        for: content,
        options: [],
        shouldFailOnDataError: shouldFailOnDataError
      )
    }

    guard let request = BridgeAPIRequest(
      protocolType: .native,
      scheme: URLScheme.messengerApp,
      methodName: ShareBridgeAPI.MethodName.share,
      parameters: parameters,
      userInfo: nil
    ) else {
      // This should probably return false instead; it's true because there wasn't
      // a false return after this in the original Objective-C.
      return true
    }

    let shouldUseSafariViewController = ShareDialogConfiguration()
      .shouldUseSafariViewController(forDialogName: FBSDKDialogConfigurationNameMessage)

    BridgeAPI.shared.open(
      request,
      useSafariViewController: shouldUseSafariViewController,
      from: nil
    ) { response in
      self.handleCompletion(
        dialogResults: response.responseParameters ?? [:],
        response: response
      )
      InternalUtility.shared.unregisterTransientObject(self)
    }

    logDialogShow()
    InternalUtility.shared.registerTransientObject(self)

    return true
  }

  /**
   Validates the content on the receiver.
   @return `true` if the content is valid, otherwise `false`.
   */
  public func validate() throws {
    guard let content = shareContent else {
      let error = ErrorFactory().requiredArgumentError(
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
      throw ErrorFactory().requiredArgumentError(
        domain: ShareErrorDomain,
        name: "shareContent",
        message: message,
        underlyingError: nil
      )
    }

    try _ShareUtility.validateShareContent(content)
  }

  private var canShowNative: Bool {
    let shouldUseNativeDialog = shareDialogConfiguration.shouldUseNativeDialog(
      forDialogName: FBSDKDialogConfigurationNameMessage
    )
    return shouldUseNativeDialog && appAvailabilityChecker.isMessengerAppInstalled
  }

  private func handleCompletion(dialogResults: [String: Any], response: BridgeAPIResponse) {
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

    AppEvents.shared.logInternalEvent(
      .messengerShareDialogResult,
      parameters: parameters,
      isImplicitlyLogged: true,
      accessToken: AccessToken.current
    )

    delegate?.sharerDidCancel(self)
  }

  private func invokeDelegateDidComplete(results: [String: Any]) {
    let parameters: [AppEvents.ParameterName: Any] = [
      .outcome: ShareAppEventsParameters.DialogOutcomeValue.completed,
    ]

    AppEvents.shared.logInternalEvent(
      .messengerShareDialogResult,
      parameters: parameters,
      isImplicitlyLogged: true,
      accessToken: AccessToken.current
    )

    delegate?.sharer(self, didCompleteWithResults: results)
  }

  private func invokeDelegateDidFail(error: Error) {
    var parameters: [AppEvents.ParameterName: Any] = [
      .outcome: ShareAppEventsParameters.DialogOutcomeValue.failed,
    ]

    parameters[.errorMessage] = String(describing: error)

    AppEvents.shared.logInternalEvent(
      .shareDialogResult,
      parameters: parameters,
      isImplicitlyLogged: true,
      accessToken: AccessToken.current
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

    AppEvents.shared.logInternalEvent(
      .shareDialogShow,
      parameters: parameters,
      isImplicitlyLogged: true,
      accessToken: AccessToken.current
    )
  }
}

#endif
