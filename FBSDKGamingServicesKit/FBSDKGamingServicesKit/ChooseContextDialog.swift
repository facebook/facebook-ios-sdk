/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !os(tvOS)

import FBSDKCoreKit
import Foundation

/// A dialog for the choose context through app switch
@objcMembers
@objc(FBSDKChooseContextDialog)
public final class ChooseContextDialog: ContextWebDialog, URLOpening {

  private enum Constants {
    static let contextKey = "context_id"
    static let contextSize = "context_size"
    static let errorMessage = "error_message"
  }

  private var internalUtility: InternalUtilityProtocol
  private var urlFactory: DialogDeeplinkURLCreating

  /**
   Convenience method to build up a choose context app switch with content and a delegate.
   @param content The content for the choose context dialog
   @param delegate The receiver's delegate.
   */
  public convenience init(
    content: ChooseContextContent,
    delegate: ContextDialogDelegate
  ) {
    self.init(content, delegate: delegate, internalUtility: InternalUtility.shared)
  }

  init(
    _ content: ChooseContextContent,
    delegate: ContextDialogDelegate,
    internalUtility: InternalUtilityProtocol
  ) {
    self.internalUtility = internalUtility
    urlFactory = ChooseContextDialogURLFactory(appID: Settings.shared.appID ?? "", content: content)
    super.init(delegate: delegate, dialogContent: content)
  }

  public override func show() -> Bool {
    var dialogURL: URL
    do {
      try validate()
      dialogURL = try urlFactory.generateDialogDeeplinkURL()
    } catch {
      handleDialogError(error as NSError)
      return false
    }

    BridgeAPI.shared.open(
      dialogURL,
      sender: self
    ) { [weak self] success, bridgeError in
      guard let self = self else {
        return
      }

      if !success, bridgeError != nil {
        let sdkError = ErrorFactory().error(
          code: CoreError.errorBridgeAPIInterruption.rawValue,
          userInfo: nil,
          message: "Error occurred while interacting with Gaming Services, Failed to open bridge.",
          underlyingError: bridgeError
        )
        self.handleDialogError(sdkError)
      }
    }
    return true
  }

  public override func validate() throws {
    guard Settings.shared.appID != nil else {
      throw ErrorFactory().error(
        code: CoreError.errorUnknown.rawValue,
        userInfo: nil,
        message: "App ID is not set in settings",
        underlyingError: nil
      )
    }
    try dialogContent?.validate()
  }

  private func handleDialogError(_ dialogError: Error) {
    delegate?.contextDialog(self, didFailWithError: dialogError)
  }

  func gamingContextFromURL(_ url: URL) throws -> GamingContext? {
    let urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false)
    guard let queryItems = urlComponents?.queryItems, !queryItems.isEmpty else {
      return nil
    }
    return try extractGamingContext(from: queryItems)
  }

  private func extractGamingContext(from queryItems: [URLQueryItem]) throws -> GamingContext? {
    var contextID: String?
    var contextSize = 0

    for queryItem in queryItems {
      if queryItem.name == Constants.contextKey, let identifier = queryItem.value {
        contextID = identifier
      }
      if queryItem.name == Constants.contextSize, let size = Int(queryItem.value ?? "") {
        contextSize = size
      }
      if queryItem.name == Constants.errorMessage, let errorMessage = queryItem.value {
        throw ErrorFactory().unknownError(message: errorMessage, userInfo: nil)
      }
    }

    guard let identifier = contextID, !identifier.isEmpty else {
      return nil
    }
    return GamingContext(identifier: identifier, size: contextSize)
  }

  // MARK: - URLOpening

  public func application(
    _ application: UIApplication?,
    open url: URL?,
    sourceApplication: String?,
    annotation: Any?
  ) -> Bool {
    guard
      let url = url,
      canOpen(
        url,
        for: application,
        sourceApplication: sourceApplication,
        annotation: annotation
      )
    else {
      return false
    }

    var gameContext: GamingContext?
    do {
      gameContext = try gamingContextFromURL(url)
    } catch {
      handleDialogError(error)
      return false
    }

    if gameContext != nil {
      delegate?.contextDialogDidComplete(self)
    } else {
      delegate?.contextDialogDidCancel(self)
    }
    return true
  }

  public func canOpen(
    _ url: URL,
    for application: UIApplication?,
    sourceApplication: String?,
    annotation: Any?
  ) -> Bool {
    guard let appID = Settings.shared.appID else {
      return false
    }
    let isCorrectScheme = url.scheme?.hasPrefix("fb\(appID)") ?? false
    let isCorrectHost = url.host?.elementsEqual("gaming") ?? false
    let isCorrectPath = url.path.elementsEqual("/contextchoose")
    return isCorrectScheme && isCorrectHost && isCorrectPath
  }

  public func applicationDidBecomeActive(_ application: UIApplication) {
    delegate?.contextDialogDidCancel(self)
  }

  public func isAuthenticationURL(_ url: URL) -> Bool {
    false
  }
}

#endif
