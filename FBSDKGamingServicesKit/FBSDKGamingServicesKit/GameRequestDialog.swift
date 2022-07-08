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
import FBSDKShareKit
import Foundation

/// A dialog for sending game requests.
@objcMembers
@objc(FBSDKGameRequestDialog)
public final class GameRequestDialog: NSObject {

  /// The receiver's delegate or nil if it doesn't have a delegate.
  public weak var delegate: GameRequestDialogDelegate?

  /// The content for game request.
  public var content: GameRequestContent

  /// Specifies whether frictionless requests are enabled.
  public var isFrictionlessRequestsEnabled = false

  /**
   A Boolean value that indicates whether the receiver can initiate a game request.

   May return `false` if the appropriate Facebook app is not installed and is required or an access token is
   required but not available.  This method does not validate the content on the receiver, so this can be checked before
   building up the content.

   See `validate()`

   @return `true` if the receiver can share, otherwise `false`.
   */
  public var canShow: Bool { true }

  private var dialogIsFrictionless = false
  private var isAwaitingResult = false
  private lazy var webDialog = WebDialog(
    name: GameRequestDialog.appRequestMethodName,
    delegate: self
  )

  private static let recipientCache = GameRequestFrictionlessRecipientCache()
  private static let appRequestMethodName = "apprequests"
  private static let gameRequestURLHost = "game_requests"

  var configuredDependencies: InstanceDependencies?

  var defaultDependencies: InstanceDependencies? = InstanceDependencies(
    bridgeAPIRequestOpener: BridgeAPI.shared,
    errorFactory: ErrorFactory(),
    gameRequestURLProvider: GameRequestURLProvider.self,
    internalUtility: InternalUtility.shared,
    logger: Logger.self,
    settings: Settings.shared,
    shareValidator: _ShareUtility.self,
    utility: Utility.self
  )

  public init(content: GameRequestContent, delegate: GameRequestDialogDelegate?) {
    self.content = content
    self.delegate = delegate
  }

  /**
   Convenience method to build up a game request with content and a delegate.
   @param content The content for the game request.
   @param delegate The receiver's delegate.
   */

  @objc(dialogWithContent:delegate:)
  public static func dialog(
    content: GameRequestContent,
    delegate: GameRequestDialogDelegate?
  ) -> GameRequestDialog {
    GameRequestDialog(content: content, delegate: delegate)
  }

  /**
   Convenience method to build up and show a game request with content and a delegate.
   @param content The content for the game request.
   @param delegate The receiver's delegate.
   */
  @objc(showWithContent:delegate:)
  @discardableResult
  public static func show(
    content: GameRequestContent,
    delegate: GameRequestDialogDelegate?
  ) -> GameRequestDialog {
    show(dialog: GameRequestDialog(content: content, delegate: delegate))
  }

  /// Testable implementation of the public static `show` method. Allows us to configure dependencies on the
  /// dialog that is acted upon.
  static func show(dialog: GameRequestDialog) -> GameRequestDialog {
    guard let dependencies = try? dialog.getDependencies() else { return dialog }

    if dependencies.utility.getGraphDomainFromToken() == "gaming",
       dependencies.internalUtility.isFacebookAppInstalled {
      dialog.launch()
    } else {
      dialog.show()
    }

    return dialog
  }

  private func launch() {
    do {
      try validate()
    } catch {
      return handleDialogError(error)
    }

    let contentDictionary = convertGameRequestContentToDictionaryV2()

    guard
      let dependencies = try? getDependencies(),
      let url = dependencies.gameRequestURLProvider.createDeepLinkURL(queryDictionary: contentDictionary)
    else { return }

    isAwaitingResult = true
    dependencies.bridgeAPIRequestOpener.open(url, sender: self) { [weak self] success, potentialError in
      guard success else { return }

      if let error = potentialError {
        self?.handleBridgeAPIFailure(error)
      }
    }
  }

  private func facebookAppReturnedURL(_ url: URL) {
    cleanUp()
    guard let results = parsePayload(from: url) else { return }

    delegate?.gameRequestDialog(self, didCompleteWithResults: results)
  }

  private func handleDialogError(_ error: Error) {
    delegate?.gameRequestDialog(self, didFailWithError: error)
    cleanUp()
  }

  private func handleBridgeAPIFailure(_ error: Error) {
    // swiftformat:disable:next redundantSelf
    guard let errorFactory = self.errorFactory else { return }

    let bridgeAPIError = errorFactory.error(
      code: CoreError.errorBridgeAPIInterruption.rawValue,
      userInfo: nil,
      message: "Error occured while interacting with Gaming Services, Failed to open bridge.",
      underlyingError: error
    )
    handleDialogError(bridgeAPIError)
  }

  private func isValidCallbackURL(_ url: URL) -> Bool {
    guard let scheme = url.scheme,
          let host = url.host
    else { return false }

    // swiftformat:disable:next redundantSelf
    let appID = self.settings?.appID ?? ""
    let schemePrefixMatches = scheme.hasPrefix("fb\(appID)")
    let hostMatches = (host == Self.gameRequestURLHost)
    return schemePrefixMatches && hostMatches
  }

  private enum PayloadKeys {
    static let requestID = "request_id"
    static let recipients = "recipients"
  }

  private func parsePayload(from url: URL) -> [String: Any]? {
    // If the URL contains no query items, then the user self closed the dialog within fbios.
    guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
          let queryItems = components.queryItems,
          queryItems.contains(where: { $0.name == PayloadKeys.requestID })
    else {
      didCancel()
      return nil
    }

    var payload = [String: Any]()
    if let requestIDItem = queryItems.last(where: { $0.name == PayloadKeys.requestID }),
       let value = requestIDItem.value {
      payload[requestIDItem.name] = value
    }
    if let recipientsItem = queryItems.last(where: { $0.name == PayloadKeys.recipients }),
       let recipients = recipientsItem.value {
      payload[recipientsItem.name] = recipients.components(separatedBy: ",")
    }

    return payload
  }

  /**
   Begins the game request from the receiver.
   @return `true` if the receiver was able to show the dialog, otherwise `false`.
   */
  @discardableResult
  public func show() -> Bool {
    guard let dependencies = try? getDependencies() else { return false }

    do {
      try validate()
    } catch {
      delegate?.gameRequestDialog(self, didFailWithError: error)
      return false
    }

    var parameters = convertGameRequestContentToDictionaryV1()

    // check if we are sending to a specific set of recipients.  if we are and they are all frictionless recipients, we
    // can perform this action without displaying the web dialog
    webDialog.shouldDeferVisibility = false

    if isFrictionlessRequestsEnabled {
      // specify these parameters to get the frictionless recipients from the dialog when it is presented
      parameters["frictionless"] = true
      parameters["get_frictionless_recipients"] = true

      dialogIsFrictionless = true
      if Self.recipientCache.recipientsAreFrictionless(content.recipients) {
        webDialog.shouldDeferVisibility = true
      }
    }

    launchViaBridgeAPI(parameters: parameters)

    dependencies.internalUtility.registerTransientObject(self)
    return true
  }

  /// Validates the content on the receiver.
  @objc(validateWithError:)
  public func validate() throws {
    let validator = try getDependencies().shareValidator
    try validator.validateRequiredValue(content, named: "content")
    try content.validate(options: [])
  }

  private func convertGameRequestContentToDictionaryV1() -> [String: Any] {
    // swiftformat:disable:next redundantSelf
    guard let urlProvider = self.gameRequestURLProvider else { return [:] }

    var parameters: [String: Any] = [
      "to": content.recipients.joined(separator: ","),
      "message": content.message,
      "object_id": content.objectID,
      "title": content.title,
      "suggestions": content.recipientSuggestions.joined(separator: ","),
    ]

    if let actionTypeName = urlProvider.actionTypeName(for: content.actionType) {
      parameters["action_type"] = actionTypeName
    }
    if let data = content.data {
      parameters["data"] = data
    }
    if let filtersName = urlProvider.filtersName(for: content.filters) {
      parameters["filters"] = filtersName
    }

    return parameters
  }

  private func convertGameRequestContentToDictionaryV2() -> [String: Any] {
    // swiftformat:disable:next redundantSelf
    guard let urlProvider = self.gameRequestURLProvider else { return [:] }

    var parameters: [String: Any] = [
      "to": content.recipientSuggestions.joined(separator: ","),
      "message": content.message,
      "object_id": content.objectID,
      "title": content.title,
      "cta": content.cta,
    ]

    if let actionTypeName = urlProvider.actionTypeName(for: content.actionType) {
      parameters["action_type"] = actionTypeName
    }
    if let data = content.data {
      parameters["data"] = data
    }
    if let filtersName = urlProvider.filtersName(for: content.filters) {
      parameters["options"] = filtersName
    }

    return parameters
  }

  private func launchViaBridgeAPI(parameters: [String: Any]) {
    guard let dependencies = try? getDependencies() else { return }

    guard let topMostViewController = dependencies.internalUtility.topMostViewController() else {
      dependencies.logger.singleShotLogEntry(
        .developerErrors,
        logEntry: "There are no valid ViewController to present FBSDKWebDialog"
      )
      return handleCompletion()
    }

    let potentialRequest = BridgeAPIRequest(
      protocolType: .web,
      scheme: .https,
      methodName: Self.appRequestMethodName,
      parameters: parameters,
      userInfo: nil
    )

    guard let request = potentialRequest else { return }

    dependencies.internalUtility.registerTransientObject(self)

    dependencies.bridgeAPIRequestOpener.open(
      request,
      useSafariViewController: false,
      from: topMostViewController
    ) { [weak self] response in
      self?.handleBridgeAPIResponse(response)
    }
  }

  private func handleBridgeAPIResponse(_ response: BridgeAPIResponse) {
    if response.isCancelled {
      didCancel()
    } else if let error = response.error {
      didFail(error: error)
    } else {
      didComplete(results: response.responseParameters)
    }
  }

  private func didComplete(results potentialResults: [String: Any]?) {
    guard let dependencies = try? getDependencies() else { return }

    guard var results = potentialResults else {
      let error = dependencies.errorFactory.error(
        domain: ShareErrorDomain,
        code: ShareError.unknown.rawValue,
        userInfo: nil,
        message: nil,
        underlyingError: nil
      )
      return handleCompletion(error: error)
    }

    if dialogIsFrictionless {
      Self.recipientCache.update(results: results)
    }

    cleanUp()

    let unsignedErrorCode = (results["error_code"] as? UInt) ?? 0
    let errorCode = Int(exactly: unsignedErrorCode) ?? 0

    let error = dependencies.errorFactory.error(
      code: errorCode,
      userInfo: nil,
      message: results["error_message"] as? String,
      underlyingError: nil
    )

    if errorCode != 0 {
      // reformat "to[x]" keys into an array.
      var index = 0
      var recipients = [Any]()
      while true {
        if let result = results["to[\(index)]"] {
          recipients.append(result)
        } else {
          break
        }

        index += 1
      }

      if !recipients.isEmpty {
        results["to"] = recipients
      }
    }

    handleCompletion(dialogResults: results, error: error)
    dependencies.internalUtility.unregisterTransientObject(self)
  }

  private func didFail(error: Error) {
    cleanUp()
    handleCompletion(error: error)
    // swiftformat:disable:next redundantSelf
    self.internalUtility?.unregisterTransientObject(self)
  }

  private func didCancel() {
    cleanUp()
    delegate?.gameRequestDialogDidCancel(self)
    // swiftformat:disable:next redundantSelf
    self.internalUtility?.unregisterTransientObject(self)
  }

  private func cleanUp() {
    dialogIsFrictionless = false
    isAwaitingResult = false
  }

  private func handleCompletion(dialogResults: [String: Any]? = nil, error: Error? = nil) {
    let nsError = error as NSError?
    let errorCode = nsError?.code ?? 0

    if errorCode == 0,
       let results = dialogResults {
      delegate?.gameRequestDialog(self, didCompleteWithResults: results)
    } else if errorCode == 4201 {
      delegate?.gameRequestDialogDidCancel(self)
    } else if let error = error {
      delegate?.gameRequestDialog(self, didFailWithError: error)
    }
  }
}

extension GameRequestDialog: WebDialogDelegate {
  public func webDialog(_ webDialog: WebDialog, didCompleteWithResults results: [String: Any]) {
    guard self.webDialog === webDialog else { return }

    didComplete(results: results)
  }

  public func webDialog(_ webDialog: WebDialog, didFailWithError error: Error) {
    guard self.webDialog === webDialog else { return }

    didFail(error: error)
  }

  public func webDialogDidCancel(_ webDialog: WebDialog) {
    guard self.webDialog === webDialog else { return }

    didCancel()
  }
}

extension GameRequestDialog: URLOpening {
  public func application(
    _ application: UIApplication?,
    open potentialURL: URL?,
    sourceApplication: String?,
    annotation: Any?
  ) -> Bool {
    guard let url = potentialURL else { return false }

    let isGamingUrl = canOpen(
      url,
      for: application,
      sourceApplication: sourceApplication,
      annotation: annotation
    )

    if isGamingUrl,
       isAwaitingResult {
      facebookAppReturnedURL(url)
    }

    return isGamingUrl
  }

  public func canOpen(
    _ url: URL,
    for application: UIApplication?,
    sourceApplication: String?,
    annotation: Any?
  ) -> Bool {
    isValidCallbackURL(url)
  }

  public func applicationDidBecomeActive(_ application: UIApplication) {
    if isAwaitingResult {
      didCancel()
    }
  }

  public func isAuthenticationURL(_ url: URL) -> Bool {
    false
  }
}

extension GameRequestDialog: DependentAsInstance {
  struct InstanceDependencies {
    var bridgeAPIRequestOpener: BridgeAPIRequestOpening
    var errorFactory: ErrorCreating
    var gameRequestURLProvider: GameRequestURLProviding.Type
    var internalUtility: InternalUtilityProtocol
    var logger: GamingLogging.Type
    var settings: SettingsProtocol
    var shareValidator: GamingShareValidating.Type
    var utility: GamingUtility.Type
  }
}

#endif
