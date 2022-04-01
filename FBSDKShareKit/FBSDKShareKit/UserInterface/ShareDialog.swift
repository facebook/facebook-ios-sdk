/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !os(tvOS)

import FBSDKCoreKit
import FBSDKCoreKit_Basics
import Foundation
import Photos
import UIKit

/// A dialog for sharing content on Facebook.
@objcMembers
@objc(FBSDKShareDialog)
public class ShareDialog: NSObject, SharingDialog { // swiftlint:disable:this prefer_final_classes
  private struct MissingContentError: Error {}
  private struct UnknownValidationError: Error {}
  private struct BridgeRequestCreationError: Error {}

  private static let feedMethodName = "feed"

  private static var hasValidatedURLSchemeRegistration = false
  private static var temporaryDirectory = URL(
    fileURLWithPath: NSTemporaryDirectory(),
    isDirectory: true
  )

  /**
   A UIViewController from which to present the dialog.

   If not specified, the topmost view controller will be automatically determined as best as possible.
   */
  public weak var fromViewController: UIViewController?

  /**
   The mode with which to display the dialog.

   Defaults to `.automatic`, which will automatically choose the best available mode.
   */
  public var mode = Mode.automatic

  /// The receiver's delegate or nil if it doesn't have a delegate.
  public weak var delegate: SharingDelegate?

  /// The content to be shared.
  public var shareContent: SharingContent?

  /**
   A Boolean value that indicates whether the receiver should fail if it finds an error with the share content.

   If `false`, the sharer will still be displayed without the data that was misconfigured.  For example, an
   invalid `placeID` specified on the `shareContent` would produce a data error.
   */
  public var shouldFailOnDataError = false

  var webDialog: WebDialog?
  private var temporaryFiles = [URL]()

  /**
   Convenience initializer to initialize a `ShareDialog` with a view controller, content and delegate.
   @param viewController A view controller from which to present the dialog, if appropriate.
   @param content The content to be shared.
   @param delegate The dialog's delegate.
   */
  @objc(initWithViewController:content:delegate:)
  public init(
    viewController: UIViewController?,
    content: SharingContent?,
    delegate: SharingDelegate?
  ) {
    fromViewController = viewController
    shareContent = content
    self.delegate = delegate

    super.init()
  }

  deinit {
    temporaryFiles.forEach { url in
      try? FileManager.default.removeItem(at: url)
    }
  }

  /**
   Convenience method to create a `ShareDialog` with a view controller, content and delegate.
   @param viewController A view controller from which to present the dialog, if appropriate.
   @param content The content to be shared.
   @param delegate The dialog's delegate.
   */
  @objc(dialogWithViewController:withContent:delegate:)
  public class func dialog(
    viewController: UIViewController?,
    content: SharingContent?,
    delegate: SharingDelegate?
  ) -> ShareDialog {
    ShareDialog(viewController: viewController, content: content, delegate: delegate)
  }

  /**
   Convenience method to show a `ShareDialog` with a view controller, content and delegate.
   @param viewController A view controller from which to present the dialog, if appropriate.
   @param content The content to be shared.
   @param delegate The dialog's delegate.
   */
  @discardableResult
  @objc(showFromViewController:withContent:delegate:)
  public class func show(
    viewController: UIViewController?,
    content: SharingContent?,
    delegate: SharingDelegate?
  ) -> ShareDialog {
    let dialog = ShareDialog(viewController: viewController, content: content, delegate: delegate)
    dialog.show()
    return dialog
  }
}

// MARK: - Type Dependencies

extension ShareDialog: DependentType {
  struct Dependencies {
    var internalURLOpener: ShareInternalURLOpening
    var internalUtility: InternalUtilityProtocol
    var settings: SettingsProtocol
    var shareUtility: (ShareUtilityProtocol & ShareValidating).Type
    var bridgeAPIRequestFactory: BridgeAPIRequestCreating
    var bridgeAPIRequestOpener: BridgeAPIRequestOpening
    var socialComposeViewControllerFactory: SocialComposeViewControllerFactoryProtocol
    var windowFinder: _WindowFinding
    var errorFactory: ErrorCreating
    var eventLogger: ShareEventLogging
    var mediaLibrarySearcher: MediaLibrarySearching
  }

  static var configuredDependencies: Dependencies?

  static var defaultDependencies: Dependencies? = Dependencies(
    internalURLOpener: ShareUIApplication.shared,
    internalUtility: InternalUtility.shared,
    settings: Settings.shared,
    shareUtility: _ShareUtility.self,
    bridgeAPIRequestFactory: ShareBridgeAPIRequestFactory(),
    bridgeAPIRequestOpener: BridgeAPI.shared,
    socialComposeViewControllerFactory: SocialComposeViewControllerFactory(),
    windowFinder: InternalUtility.shared,
    errorFactory: ErrorFactory(),
    eventLogger: AppEvents.shared,
    mediaLibrarySearcher: PHImageManager.default()
  )

  #if DEBUG
  static func resetDependencies() {
    configuredDependencies = nil
    hasValidatedURLSchemeRegistration = false
  }
  #endif
}

extension ShareDialog {

  private static func validateURLSchemeRegistration() throws {
    guard !hasValidatedURLSchemeRegistration else { return }

    let internalUtility = try getDependencies().internalUtility

    internalUtility.checkRegisteredCanOpenURLScheme(URLScheme.facebookAPI.rawValue)
    hasValidatedURLSchemeRegistration = true
  }

  public var canShow: Bool {
    guard shareContent != nil else {
      return canShowWithoutContent
    }

    do {
      try validate()
      return true
    } catch {
      return false
    }
  }

  private var canShowWithoutContent: Bool {
    switch mode {
    case .automatic,
         .browser,
         .feedBrowser,
         .feedWeb,
         .web:
      return true
    case .native:
      return canShowNative
    case .shareSheet:
      return canShowShareSheet
    default:
      return false
    }
  }

  @discardableResult
  public func show() -> Bool {
    guard let internalUtility = try? Self.getDependencies().internalUtility else {
      return false
    }

    do {
      try validate()

      switch mode {
      case .automatic:
        try showAutomatic()
      case .browser:
        try showBrowser()
      case .feedBrowser:
        try showFeedBrowser()
      case .feedWeb:
        try showFeedWeb()
      case .native:
        try showNative()
      case .shareSheet:
        try showShareSheet()
      case .web:
        try showWeb()
      }

      logDialogShow()
      internalUtility.registerTransientObject(self)
      return true
    } catch {
      invokeDelegateDidFail(error: error)
      return false
    }
  }

  private var shouldDefaultToShareSheet: Bool {
    if shareContent is ShareCameraEffectContent {
      return false
    } else {
      return ShareDialogConfiguration().defaultShareMode == "share_sheet"
    }
  }

  private func showAutomatic() throws {
    let defaultToShareSheet = shouldDefaultToShareSheet
    let useNativeDialog = shouldUseNativeDialog

    if defaultToShareSheet,
       doesNotThrow(try showShareSheet()) {
      return
    }

    if useNativeDialog,
       doesNotThrow(try showNative()) {
      return
    }

    if !defaultToShareSheet,
       doesNotThrow(try showShareSheet()) {
      return
    }

    if doesNotThrow(try showFeedBrowser()) {
      return
    }

    if doesNotThrow(try showFeedWeb()) {
      return
    }

    if doesNotThrow(try showBrowser()) {
      return
    }

    let showWebError: Error
    do {
      try showWeb()
      return
    } catch {
      showWebError = error
    }

    if !useNativeDialog {
      try showNative()
    } else {
      throw showWebError
    }
  }

  // This method helps us turn a chain of validation methods into a predicate
  private func doesNotThrow(_ invocation: @autoclosure () throws -> Void) -> Bool {
    do {
      try invocation()
      return true
    } catch {
      return false
    }
  }

  private var canShowNative: Bool {
    guard let internalUtility = try? Self.getDependencies().internalUtility else {
      return false
    }

    return internalUtility.isFacebookAppInstalled
  }

  private var canShowShareSheet: Bool {
    guard let internalUtility = try? Self.getDependencies().internalUtility else {
      return false
    }

    return internalUtility.isFacebookAppInstalled
  }

  private var canAttributeThroughShareSheet: Bool {
    do {
      try Self.validateURLSchemeRegistration()
    } catch {
      return false
    }

    var components = URLComponents()
    components.scheme = URLScheme.facebookAPI.rawValue
    components.path = "/"

    var canOpenURL = false
    if let url = components.url,
       let internalURLOpener = try? Self.getDependencies().internalURLOpener {
      canOpenURL = internalURLOpener.canOpenURL(url)
    }

    return canOpenURL || canUseFBShareSheet
  }

  private var canUseFBShareSheet: Bool {
    guard let urlOpener = try? Self.getDependencies().internalURLOpener else {
      return false
    }

    var components = URLComponents()
    components.scheme = URLScheme.facebookAPI.rawValue
    components.path = "/"

    guard let url = components.url else { return false }

    return urlOpener.canOpenURL(url)
  }

  private var contentImages: [UIImage] {
    if let photoContent = shareContent as? SharePhotoContent {
      let uniqueImages = Set(photoContent.photos.compactMap(\.image))
      return Array(uniqueImages)
    } else if let mediaContent = shareContent as? ShareMediaContent {
      return mediaContent.media.compactMap { ($0 as? SharePhoto)?.image }
    } else {
      return []
    }
  }

  private func contentVideoURL(for video: ShareVideo) -> URL? {
    if let asset = video.videoAsset {
      guard let mediaLibrarySearcher = try? Self.getDependencies().mediaLibrarySearcher else {
        return nil
      }

      return try? mediaLibrarySearcher.fb_getVideoURL(for: asset)
    } else if let data = video.data {
      let file = Self.temporaryDirectory.appendingPathComponent(UUID().uuidString)
      temporaryFiles.append(file)

      do {
        try data.write(to: file, options: .atomic)
        return file
      } catch {
        return nil
      }
    } else {
      return video.videoURL
    }
  }

  private var contentVideoURLs: [URL] {
    if let videoContent = shareContent as? ShareVideoContent,
       let url = contentVideoURL(for: videoContent.video) {
      return [url]
    } else if let mediaContent = shareContent as? ShareMediaContent {
      return mediaContent.media
        .compactMap { $0 as? ShareVideo }
        .compactMap(contentVideoURL(for:))
    } else {
      return []
    }
  }

  private var contentURLs: [URL]? {
    if let linkContent = shareContent as? ShareLinkContent,
       let url = linkContent.contentURL {
      return [url]
    } else if let photoContent = shareContent as? SharePhotoContent,
              let url = photoContent.contentURL {
      return [url]
    } else {
      return nil
    }
  }

  private func handleWebResponse(
    parameters: [String: Any]? = nil,
    error potentialError: Error? = nil,
    isCancelled: Bool
  ) {
    if let error = potentialError {
      return invokeDelegateDidFail(error: error)
    }

    let completionGesture = parameters?[ShareBridgeAPI.CompletionGesture.key] as? String
    if (completionGesture == ShareBridgeAPI.CompletionGesture.cancelValue) || isCancelled {
      invokeDelegateDidCancel()
    } else {
      // Not all web dialogs report cancellation, so assume that the share has completed
      // with no additional information
      var results = [String: Any]()

      // The web response comes back with a different payload, so we need to translate it
      if let postID = parameters?[ShareBridgeAPI.PostIDKey.webParameters] {
        results[ShareBridgeAPI.PostIDKey.results] = postID
      }

      invokeDelegateDidComplete(results: results)
    }
  }

  private func photoContentHasAtLeastOneImage(_ photoContent: SharePhotoContent) -> Bool {
    photoContent.photos.contains { $0.image != nil }
  }

  private func showBrowser() throws {
    let dependencies = try Self.getDependencies()

    guard let content = shareContent else {
      throw MissingContentError()
    }

    try validateShareContentForBrowser()

    if let photoContent = content as? SharePhotoContent,
       photoContentHasAtLeastOneImage(photoContent) {
      dependencies.shareUtility.buildAsyncWebPhotoContent(photoContent) { [self] success, methodName, parameters in
        guard
          success,
          let request = dependencies.bridgeAPIRequestFactory.bridgeAPIRequest(
            with: .web,
            scheme: URLScheme.https.rawValue,
            methodName: methodName,
            parameters: parameters,
            userInfo: nil
          )
        else { return }

        dependencies.bridgeAPIRequestOpener.open(
          request,
          useSafariViewController: shouldUseSafariViewController,
          from: fromViewController
        ) { [self] response in
          handleWebResponse(
            parameters: response.responseParameters,
            error: response.error,
            isCancelled: response.isCancelled
          )

          dependencies.internalUtility.unregisterTransientObject(self)
        }
      }
    } else {
      let components = dependencies.shareUtility.buildWebShareBridgeComponents(for: content)
      guard let request = dependencies.bridgeAPIRequestFactory.bridgeAPIRequest(
        with: .web,
        scheme: URLScheme.https.rawValue,
        methodName: components.methodName,
        parameters: components.parameters,
        userInfo: nil
      )
      else {
        throw BridgeRequestCreationError()
      }

      dependencies.bridgeAPIRequestOpener.open(
        request,
        useSafariViewController: shouldUseSafariViewController,
        from: fromViewController
      ) { [self] response in
        handleWebResponse(
          parameters: response.responseParameters,
          error: response.error,
          isCancelled: response.isCancelled
        )

        dependencies.internalUtility.unregisterTransientObject(self)
      }
    }
  }

  private func showFeedBrowser() throws {
    try validateShareContentForFeed()
    let dependencies = try Self.getDependencies()

    guard let content = shareContent else {
      throw MissingContentError()
    }

    let parameters = dependencies.shareUtility.feedShareDictionary(for: content)
    guard let request = dependencies.bridgeAPIRequestFactory.bridgeAPIRequest(
      with: .web,
      scheme: URLScheme.https.rawValue,
      methodName: Self.feedMethodName,
      parameters: parameters,
      userInfo: nil
    )
    else {
      throw BridgeRequestCreationError()
    }

    dependencies.bridgeAPIRequestOpener.open(
      request,
      useSafariViewController: shouldUseSafariViewController,
      from: fromViewController
    ) { [self] response in
      handleWebResponse(
        parameters: response.responseParameters,
        error: response.error,
        isCancelled: response.isCancelled
      )

      dependencies.internalUtility.unregisterTransientObject(self)
    }
  }

  private func showFeedWeb() throws {
    try validateShareContentForFeed()
    let dependencies = try Self.getDependencies()

    guard let content = shareContent else {
      throw MissingContentError()
    }

    let parameters = dependencies.shareUtility.feedShareDictionary(for: content)
    webDialog = WebDialog.createAndShow(
      name: Self.feedMethodName,
      parameters: parameters,
      frame: .zero,
      delegate: self,
      windowFinder: dependencies.windowFinder
    )
  }

  private func showNative() throws {
    let dependencies = try Self.getDependencies()

    guard let content = shareContent else {
      throw MissingContentError()
    }

    guard canShowNative else {
      throw dependencies.errorFactory.error(
        domain: ShareErrorDomain,
        code: ShareError.dialogNotAvailable.rawValue,
        userInfo: nil,
        message: "Native share dialog is not available.",
        underlyingError: nil
      )
    }

    try validateShareContentForNative()

    let methodName = (content is ShareCameraEffectContent)
      ? ShareBridgeAPI.MethodName.camera
      : ShareBridgeAPI.MethodName.share

    let parameters = dependencies.shareUtility.bridgeParameters(
      for: content,
      options: [],
      shouldFailOnDataError: shouldFailOnDataError
    )

    guard let request = dependencies.bridgeAPIRequestFactory.bridgeAPIRequest(
      with: .native,
      scheme: URLScheme.facebookAPI.rawValue,
      methodName: methodName,
      parameters: parameters,
      userInfo: nil
    )
    else {
      throw BridgeRequestCreationError()
    }

    dependencies.bridgeAPIRequestOpener.open(
      request,
      useSafariViewController: shouldUseSafariViewController,
      from: fromViewController
    ) { [self] response in
      let responseError = response.error as NSError?
      if responseError?.code == CoreError.errorAppVersionUnsupported.rawValue {
        do {
          try showShareSheet()
          return
        } catch {}

        do {
          try showFeedBrowser()
          return
        } catch {}
      }

      let completionGesture = response.responseParameters?[ShareBridgeAPI.CompletionGesture.key] as? String
      let didCancel = (completionGesture == ShareBridgeAPI.CompletionGesture.cancelValue)
        || response.isCancelled

      if didCancel {
        invokeDelegateDidCancel()
      } else if let error = response.error {
        invokeDelegateDidFail(error: error)
      } else {
        var results = [String: Any]()
        if let postID = response.responseParameters?[ShareBridgeAPI.PostIDKey.results] {
          results[ShareBridgeAPI.PostIDKey.results] = postID
        }
        invokeDelegateDidComplete(results: results)
      }

      dependencies.internalUtility.unregisterTransientObject(self)
    }
  }

  private func showShareSheet() throws {
    let dependencies = try Self.getDependencies()

    guard canShowShareSheet else {
      throw dependencies.errorFactory.error(
        domain: ShareErrorDomain,
        code: ShareError.dialogNotAvailable.rawValue,
        userInfo: nil,
        message: "Share sheet is not available.",
        underlyingError: nil
      )
    }

    try validateShareContentForShareSheet()

    guard let viewController = fromViewController else {
      throw dependencies.errorFactory.requiredArgumentError(
        domain: ShareErrorDomain,
        name: "fromViewController",
        message: nil,
        underlyingError: nil
      )
    }

    let composeViewController = dependencies.socialComposeViewControllerFactory.makeSocialComposeViewController()

    if let initialText = try calculateInitialText(),
       !initialText.isEmpty {
      composeViewController.setInitialText(initialText)
    }

    contentImages.forEach { image in
      composeViewController.add(image)
    }
    contentURLs?.forEach { url in
      composeViewController.add(url)
    }
    contentVideoURLs.forEach { url in
      composeViewController.add(url)
    }

    composeViewController.completionHandler = { [self] result in
      switch result {
      case .cancelled:
        invokeDelegateDidCancel()
      case .done:
        invokeDelegateDidComplete(results: [:])
      @unknown default:
        break
      }

      DispatchQueue.main.async {
        dependencies.internalUtility.unregisterTransientObject(self)
      }
    }

    viewController.present(composeViewController, animated: true)
  }

  private func showWeb() throws {
    try validateShareContentForBrowser(options: .photoImageURL)
    let dependencies = try Self.getDependencies()

    guard let content = shareContent else {
      throw MissingContentError()
    }

    let components = dependencies.shareUtility.buildWebShareBridgeComponents(for: content)

    webDialog = WebDialog.createAndShow(
      name: components.methodName,
      parameters: components.parameters,
      frame: .zero,
      delegate: self,
      windowFinder: dependencies.windowFinder
    )
  }

  private var shouldUseNativeDialog: Bool {
    if shareContent is ShareCameraEffectContent {
      return true
    } else {
      return ShareDialogConfiguration()
        .shouldUseNativeDialog(forDialogName: FBSDKDialogConfigurationNameShare)
    }
  }

  private var shouldUseSafariViewController: Bool {
    if shareContent is ShareCameraEffectContent {
      return false
    } else {
      return ShareDialogConfiguration()
        .shouldUseSafariViewController(forDialogName: FBSDKDialogConfigurationNameShare)
    }
  }

  public func validate() throws {
    let dependencies = try Self.getDependencies()

    guard let content = shareContent else {
      throw MissingContentError()
    }

    switch content {
    case is ShareCameraEffectContent,
         is ShareLinkContent,
         is ShareMediaContent,
         is SharePhotoContent,
         is ShareVideoContent:
      break
    default:
      throw dependencies.errorFactory.requiredArgumentError(
        domain: ShareErrorDomain,
        name: "shareContent",
        message: "Share dialog does not support \(type(of: content)).",
        underlyingError: nil
      )
    }

    try dependencies.shareUtility.validateShareContent(content, options: [])

    switch mode {
    case .automatic:
      try validateAutomaticMode()
    case .native:
      try validateShareContentForNative()
    case .shareSheet:
      try validateShareContentForShareSheet()
    case .browser:
      try validateShareContentForBrowser()
    case .web:
      try validateShareContentForBrowser(options: .photoImageURL)
    case .feedBrowser,
         .feedWeb:
      try validateShareContentForFeed()
    }
  }

  private func validateAutomaticMode() throws {
    if canShowNative {
      do {
        try validateShareContentForNative()
        return
      } catch {}
    }

    if canShowShareSheet {
      do {
        try validateShareContentForShareSheet()
        return
      } catch {}
    }

    do {
      try validateShareContentForFeed()
      return
    } catch {}

    try validateShareContentForBrowser()
  }

  private func validateShareContentForBrowser(options bridgeOptions: ShareBridgeOptions = []) throws {
    let dependencies = try Self.getDependencies()

    guard let content = shareContent else {
      throw MissingContentError()
    }

    if let linkContent = content as? ShareLinkContent,
       linkContent.contentURL == nil {
      throw dependencies.errorFactory.invalidArgumentError(
        domain: ShareErrorDomain,
        name: "shareContent",
        value: linkContent,
        message: "ShareLinkContent contentURL is required.",
        underlyingError: nil
      )
    }

    guard !(shareContent is ShareCameraEffectContent) else {
      throw dependencies.errorFactory.invalidArgumentError(
        domain: ShareErrorDomain,
        name: "shareContent",
        value: shareContent,
        message: "Camera Content must be shared in `Native` mode.",
        underlyingError: nil
      )
    }

    let flags = dependencies.shareUtility.getContentFlags(for: content)

    if flags.containsPhotos {
      guard AccessToken.current != nil else {
        throw dependencies.errorFactory.invalidArgumentError(
          domain: ShareErrorDomain,
          name: "shareContent",
          value: content,
          message: "The web share dialog needs a valid access token to stage photos.",
          underlyingError: nil
        )
      }

      if let photo = content as? SharePhotoContent {
        try photo.validate(options: bridgeOptions)
      } else {
        throw dependencies.errorFactory.invalidArgumentError(
          domain: ShareErrorDomain,
          name: "shareContent",
          value: content,
          message: "Web share dialogs cannot include photos.",
          underlyingError: nil
        )
      }
    }

    if flags.containsVideos {
      guard AccessToken.current != nil else {
        throw dependencies.errorFactory.invalidArgumentError(
          domain: ShareErrorDomain,
          name: "shareContent",
          value: content,
          message: "The web share dialog needs a valid access token to stage videos.",
          underlyingError: nil
        )
      }

      if let video = content as? ShareVideoContent {
        try video.validate(options: bridgeOptions)
      }
    }

    if flags.containsMedia,
       bridgeOptions == .photoImageURL { // a web-based URL is required
      throw dependencies.errorFactory.invalidArgumentError(
        domain: ShareErrorDomain,
        name: "shareContent",
        value: content,
        message: "Web share dialogs cannot include local media.",
        underlyingError: nil
      )
    }
  }

  private func validateShareContentForFeed() throws {
    let errorFactory = try Self.getDependencies().errorFactory

    if let linkContent = shareContent as? ShareLinkContent {
      if linkContent.contentURL == nil {
        throw errorFactory.invalidArgumentError(
          domain: ShareErrorDomain,
          name: "shareContent",
          value: linkContent,
          message: "ShareLinkContent contentURL is required.",
          underlyingError: nil
        )
      }
    } else {
      throw errorFactory.invalidArgumentError(
        domain: ShareErrorDomain,
        name: "shareContent",
        value: shareContent,
        message: "Feed share dialogs support ShareLinkContent.",
        underlyingError: nil
      )
    }
  }

  private func validateShareContentForNative() throws {
    let dependencies = try Self.getDependencies()

    guard let anyContent = shareContent else {
      throw MissingContentError()
    }

    switch anyContent {
    case let media as ShareMediaContent:
      if dependencies.shareUtility.shareMediaContentContainsPhotosAndVideos(media) {
        throw dependencies.errorFactory.invalidArgumentError(
          domain: ShareErrorDomain,
          name: "shareContent",
          value: media,
          message: "Multimedia Content is only available for mode `ShareSheet`",
          underlyingError: nil
        )
      }
    case is ShareVideoContent:
      return
    default:
      break
    }

    try anyContent.validate(options: [])
  }

  private func validateShareContentForShareSheet() throws {
    let errorFactory = try Self.getDependencies().errorFactory

    guard let anyContent = shareContent else { return }

    switch anyContent {
    case let photo as SharePhotoContent:
      guard contentImages.isEmpty else { return }

      throw errorFactory.invalidArgumentError(
        domain: ShareErrorDomain,
        name: "shareContent",
        value: photo,
        message: "Share photo content must have UIImage photos in order to share with the share sheet",
        underlyingError: nil
      )
    case let video as ShareVideoContent:
      guard canUseFBShareSheet else {
        throw UnknownValidationError()
      }

      return try video.validate(options: [])
    case let media as ShareMediaContent:
      guard canUseFBShareSheet else {
        throw UnknownValidationError()
      }

      try validateShareMediaContentAvailability(content: media)
      return try media.validate(options: [])
    case is ShareLinkContent:
      return
    default:
      throw errorFactory.invalidArgumentError(
        domain: ShareErrorDomain,
        name: "shareContent",
        value: anyContent,
        message: "Share sheet does not support \(type(of: anyContent)).",
        underlyingError: nil
      )
    }
  }

  private func validateShareMediaContentAvailability(content: ShareMediaContent) throws {
    let dependencies = try Self.getDependencies()

    if dependencies.shareUtility.shareMediaContentContainsPhotosAndVideos(content),
       mode == .shareSheet,
       !canUseFBShareSheet {
      throw dependencies.errorFactory.invalidArgumentError(
        domain: ShareErrorDomain,
        name: "shareContent",
        value: content,
        message: "Cannot use the share sheet if the share sheet is unavailable. Make sure the FB app is installed.",
        underlyingError: nil
      )
    }
  }

  private func invokeDelegateDidCancel() {
    AppEvents.shared.logInternalEvent(
      .shareDialogResult,
      parameters: [.outcome: ShareAppEventsParameters.DialogOutcomeValue.cancelled],
      isImplicitlyLogged: true,
      accessToken: .current
    )

    delegate?.sharerDidCancel(self)
  }

  private func invokeDelegateDidComplete(results: [String: Any]) {
    let eventLogger = try? Self.getDependencies().eventLogger
    eventLogger?.logInternalEvent(
      .shareDialogResult,
      parameters: [.outcome: ShareAppEventsParameters.DialogOutcomeValue.completed],
      isImplicitlyLogged: true,
      accessToken: .current
    )

    delegate?.sharer(self, didCompleteWithResults: results)
  }

  private func invokeDelegateDidFail(error: Error) {
    let nsError = error as NSError
    let parameters: [AppEvents.ParameterName: Any] = [
      .outcome: ShareAppEventsParameters.DialogOutcomeValue.failed,
      .errorMessage: nsError.description,
    ]

    let eventLogger = try? Self.getDependencies().eventLogger
    eventLogger?.logInternalEvent(
      .shareDialogResult,
      parameters: parameters,
      isImplicitlyLogged: true,
      accessToken: .current
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
    case is ShareCameraEffectContent:
      contentType = ShareAppEventsParameters.ContentTypeValue.camera
    default:
      contentType = ShareAppEventsParameters.ContentTypeValue.unknown
    }

    let parameters: [AppEvents.ParameterName: Any] = [
      .mode: mode.description,
      .shareContentType: contentType,
    ]

    let eventLogger = try? Self.getDependencies().eventLogger
    eventLogger?.logInternalEvent(
      .shareDialogShow,
      parameters: parameters,
      isImplicitlyLogged: true,
      accessToken: .current
    )
  }

  private enum ShareExtensionParameterKeys {
    static let appID = "app_id" // application identifier string
    static let hashtags = "hashtags" // array of hashtag strings (max 1)
    static let quotes = "quotes" // array of quote strings (max 1)
  }

  private func calculateInitialText() throws -> String? {
    let dependencies = try Self.getDependencies()
    let potentialHashtag = dependencies.shareUtility.hashtagString(from: shareContent?.hashtag)
    let hashtagIsEmpty = potentialHashtag?.isEmpty ?? true

    guard canAttributeThroughShareSheet else {
      return !hashtagIsEmpty ? potentialHashtag : nil
    }

    var parameters = [String: Any]()
    if let appID = dependencies.settings.appID,
       !appID.isEmpty {
      parameters[ShareExtensionParameterKeys.appID] = appID
    }
    if let hashtag = potentialHashtag,
       !hashtag.isEmpty {
      parameters[ShareExtensionParameterKeys.hashtags] = [hashtag]
    }
    if let content = shareContent as? ShareLinkContent,
       let quote = content.quote,
       !quote.isEmpty {
      parameters[ShareExtensionParameterKeys.quotes] = [quote]
    }

    if let json = try? BasicUtility.jsonString(for: parameters, invalidObjectHandler: nil) {
      return buildShareExtensionInitialText(
        appID: dependencies.settings.appID,
        hashtag: potentialHashtag,
        jsonString: json
      )
    } else {
      return nil
    }
  }

  private func buildShareExtensionInitialText(
    appID: String?,
    hashtag: String?,
    jsonString: String?
  ) -> String? {
    var text = ""

    // Not all versions of our Share Extension supported JSON.
    // Adding this text before the JSON payload supports backward compatibility.
    if let appID = appID,
       !appID.isEmpty {
      text += "fb-app-id:\(appID)"
    }

    if let hashtag = hashtag,
       !hashtag.isEmpty {
      if !text.isEmpty {
        text += " "
      }

      text += "\(hashtag)"
    }

    if let jsonString = jsonString,
       !jsonString.isEmpty {
      text += "|\(jsonString)"
    }

    return !text.isEmpty ? text : nil
  }
}

extension ShareDialog: WebDialogDelegate {
  public func webDialog(
    _ webDialog: WebDialog,
    didCompleteWithResults results: [String: Any]
  ) {
    guard
      webDialog === self.webDialog,
      let dependencies = try? Self.getDependencies()
    else { return }

    self.webDialog = nil

    let errorCode = (results["error_code"] as? Int) ?? 0
    if errorCode == 4201 {
      invokeDelegateDidCancel()
    } else if errorCode != 0 {
      let error = dependencies.errorFactory.error(
        domain: ShareErrorDomain,
        code: ShareError.unknown.rawValue,
        userInfo: [GraphRequestErrorGraphErrorCodeKey: errorCode],
        message: results["error_message"] as? String,
        underlyingError: nil
      )
      handleWebResponse(error: error, isCancelled: false)
    } else {
      // Not all web dialogs report cancellation, so assume that the share has completed with no additional information
      handleWebResponse(parameters: results, isCancelled: false)
    }

    dependencies.internalUtility.unregisterTransientObject(self)
  }

  public func webDialog(_ webDialog: WebDialog, didFailWithError error: Error) {
    guard self.webDialog === webDialog else { return }

    self.webDialog = nil
    invokeDelegateDidFail(error: error)

    let internalUtility = try? Self.getDependencies().internalUtility
    internalUtility?.unregisterTransientObject(self)
  }

  public func webDialogDidCancel(_ webDialog: WebDialog) {
    guard self.webDialog === webDialog else { return }

    self.webDialog = nil
    invokeDelegateDidCancel()

    let internalUtility = try? Self.getDependencies().internalUtility
    internalUtility?.unregisterTransientObject(self)
  }
}

#endif
