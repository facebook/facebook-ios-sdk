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
import UIKit

/**
 Provides methods for logging the user in and out.

 It works directly with `AccessToken` (for data access) and `AuthenticationToken` (for authentication);
 it sets the "current" tokens upon successful authorizations (or sets to `nil` in case of `logOut`).

 You should check `AccessToken.current` before calling a login method to see if there is
 a cached token available (typically in a `viewDidLoad` implementation).

 @warning If you are managing your own tokens outside of `AccessToken`, you will need to set
 `AccessToken.current` before calling a login method to authorize further permissions on your tokens.
 */
@objcMembers
@objc(FBSDKLoginManager)
public final class LoginManager: NSObject {

  /// The default audience. You should set this if you intend to ask for publish permissions.
  public var defaultAudience = DefaultAudience.friends

  var handler: IdentifiedLoginResultHandler?
  private(set) var configuration: LoginConfiguration?

  private weak var fromViewController: UIViewController?
  var requestedPermissions: Set<FBPermission>?
  var logger: _LoginManagerLogger?
  var state = _LoginManagerState.idle
  var usedSafariSession = false

  var isPerformingLogin: Bool {
    state == .performingLogin
  }

  private enum Keys {
    static let expectedChallenge = "expected_login_challenge"
    static let expectedNonce = "expected_login_nonce"
    static let expectedCodeVerifier = "expected_login_code_verifier"
  }

  private static let clientStateChallengeLength = UInt(20)
  private static let oAuthPath = "/dialog/oauth"

  private enum CanceledLoginErrorDomains {
    static let safariServices = "com.apple.SafariServices.Authentication"
    static let authenticationServices = "com.apple.AuthenticationServices.WebAuthenticationSession"

    static func isValidDomain(_ domain: String) -> Bool {
      [safariServices, authenticationServices].contains(domain)
    }
  }

  private enum LoggerAuthenticationMethod {
    static let browser = "browser_auth"
    static let safariViewController = "sfvc_auth"
  }

  var configuredDependencies: InstanceDependencies?

  lazy var defaultDependencies: InstanceDependencies? = {
    let keychainStoreFactory = KeychainStoreFactory()
    guard let bundleIdentifier = Bundle.main.bundleIdentifier else {
      fatalError("Unable to find main bundle identifier. Cannot create keychain service identifier")
    }

    let keychainStore = keychainStoreFactory.createKeychainStore(
      withService: "com.facebook.sdk.loginmanager.\(bundleIdentifier)",
      accessGroup: nil
    )

    return InstanceDependencies(
      accessTokenWallet: AccessToken.self,
      authenticationTokenWallet: AuthenticationToken.self,
      errorFactory: ErrorFactory(),
      graphRequestFactory: GraphRequestFactory(),
      internalUtility: InternalUtility.shared,
      keychainStore: keychainStore,
      loginCompleterFactory: _LoginCompleterFactory(),
      profileProvider: Profile.self,
      settings: Settings.shared,
      urlOpener: BridgeAPI.shared
    )
  }()

  /**
   Initialize an instance of `LoginManager.`

   - parameter defaultAudience: Optional default audience to use. Default: `.friends`.
   */
  public convenience init(defaultAudience: DefaultAudience = .friends) {
    self.init()
    self.defaultAudience = defaultAudience
  }

  // MARK: - Logging In

  /**
   Logs the user in or authorizes additional permissions.

   @param viewController the view controller from which to present the login UI. If nil, the topmost view
   controller will be automatically determined and used.
   @param configuration the login configuration to use.
   @param completion the login completion handler.

   Use this method when asking for permissions. You should only ask for permissions when they
   are needed and the value should be explained to the user. You can inspect the
   `FBSDKLoginManagerLoginResultBlock`'s `result.declinedPermissions` to provide more information
   to the user if they decline permissions.
   To reduce unnecessary login attempts, you should typically check if `AccessToken.current`
   already contains the permissions you need. If it does, you probably do not need to call this method.

   @warning You can only perform one login call at a time. Calling a login method before the completion handler is
   called on a previous login attempt will result in an error.
   @warning This method will present a UI to the user and thus should be called on the main thread.
   */
  @available(swift, obsoleted: 0.1)
  @objc(logInFromViewController:configuration:completion:)
  public func logIn(
    from viewController: UIViewController?,
    configuration: LoginConfiguration?,
    completion: @escaping LoginManagerLoginResultBlock
  ) {
    guard validateLoginStartState() else { return }

    commonLogIn(from: viewController, configuration: configuration, completion: completion)
  }

  /**
   Logs the user in or authorizes additional permissions.

   Use this method when asking for permissions. You should only ask for permissions when they
   are needed and the value should be explained to the user. You can inspect the result's `declinedPermissions` to also
   provide more information to the user if they decline permissions.

   This method will present a UI to the user. To reduce unnecessary app switching, you should typically check if
   `AccessToken.current` already contains the permissions you need. If it does, you probably
   do not need to call this method.

   You can only perform one login call at a time. Calling a login method before the completion handler is called
   on a previous login will result in an error.

   - parameter viewController: Optional view controller to present from. Default: topmost view controller.
   - parameter configuration the login configuration to use.
   - parameter completion: Optional callback.
   */
  @nonobjc
  public func logIn(
    viewController: UIViewController? = nil,
    configuration: LoginConfiguration?,
    completion: @escaping LoginResultBlock
  ) {
    let legacyCompletion = { (result: LoginManagerLoginResult?, error: Error?) in
      let result = LoginResult(result: result, error: error)
      completion(result)
    }

    commonLogIn(from: viewController, configuration: configuration, completion: legacyCompletion)
  }

  private func commonLogIn(
    from viewController: UIViewController?,
    configuration: LoginConfiguration?,
    completion: LoginManagerLoginResultBlock?
  ) {
    guard let configuration = configuration else {
      let failureMessage = """
        Cannot login without a valid login configuration. Please make sure the `LoginConfiguration` provided is non-nil.
        """

      Logger.singleShotLogEntry(.developerErrors, logEntry: failureMessage)

      let error = self.errorFactory?.error(
        code: CoreError.errorInvalidArgument.rawValue,
        message: failureMessage,
        underlyingError: nil
      )
      handler = completion.flatMap(IdentifiedLoginResultHandler.init)
      return invokeHandler(error: error)
    }

    fromViewController = viewController
    self.configuration = configuration
    requestedPermissions = configuration.requestedPermissions

    logIn(permissions: configuration.requestedPermissions, handler: completion)
  }

  /**
   Logs the user in or authorizes additional permissions.

   @param permissions the optional array of permissions. Note this is converted to NSSet and is only
   an NSArray for the convenience of literal syntax.
   @param viewController the view controller to present from. If nil, the topmost view controller will be
   automatically determined as best as possible.
   @param handler the callback.

   Use this method when asking for read permissions. You should only ask for permissions when they
   are needed and explain the value to the user. You can inspect the `FBSDKLoginManagerLoginResultBlock`'s
   `result.declinedPermissions` to provide more information to the user if they decline permissions.
   You typically should check if `AccessToken.current` already contains the permissions you need before
   asking to reduce unnecessary login attempts. For example, you could perform that check in `viewDidLoad`.

   @warning You can only perform one login call at a time. Calling a login method before the completion handler is
   called on a previous login attempt will result in an error.
   @warning This method will present a UI to the user and thus should be called on the main thread.
   */
  @objc(logInWithPermissions:fromViewController:handler:)
  public func logIn(
    permissions: [String],
    from viewController: UIViewController?,
    handler: LoginManagerLoginResultBlock?
  ) {
    guard validateLoginStartState() else { return }

    let configuration = LoginConfiguration(permissions: permissions, tracking: .enabled)
    commonLogIn(from: viewController, configuration: configuration, completion: handler)
  }

  /**
   Logs the user in or authorizes additional permissions.

   Use this method when asking for permissions. You should only ask for permissions when they
   are needed and the value should be explained to the user. You can inspect the result's `declinedPermissions` to also
   provide more information to the user if they decline permissions.

   This method will present a UI to the user. To reduce unnecessary app switching, you should typically check if
   `AccessToken.current` already contains the permissions you need. If it does, you probably
   do not need to call this method.

   You can only perform one login call at a time. Calling a login method before the completion handler is called
   on a previous login will result in an error.

   - parameter permissions: Array of read permissions. Default: `[.PublicProfile]`
   - parameter viewController: Optional view controller to present from. Default: topmost view controller.
   - parameter completion: Optional callback.
   */
  func logIn(
    permissions: [Permission] = [.publicProfile],
    viewController: UIViewController? = nil,
    completion: LoginResultBlock? = nil
  ) {
    logIn(
      permissions: permissions.map(\.name),
      from: viewController
    ) { result, error in
      completion?(LoginResult(result: result, error: error))
    }
  }

  private func logIn(permissions: Set<FBPermission>, handler: LoginManagerLoginResultBlock?) {
    if let configuration = configuration {
      let provider = ServerConfigurationProvider()
      logger = _LoginManagerLogger(loggingToken: provider.loggingToken, tracking: configuration.tracking)
    }

    self.handler = handler.flatMap(IdentifiedLoginResultHandler.init)

    logger?.startSession(for: self)
    logIn()
  }

  private func logIn() {
    usedSafariSession = false

    performBrowserLogIn { [self] didPerformLogIn, potentialError in
      if didPerformLogIn {
        state = .performingLogin
      } else if let error = potentialError as NSError?,
                CanceledLoginErrorDomains.isValidDomain(error.domain) {
        handleImplicitCancelOfLogIn()
      } else {
        let error = potentialError ?? NSError(domain: LoginErrorDomain, code: LoginError.unknown.rawValue)
        invokeHandler(error: error)
      }
    }
  }

  // MARK: - Reauthorization

  /**
   Requests user's permission to reathorize application's data access, after it has expired due to inactivity.
   @param viewController the view controller from which to present the login UI. If nil, the topmost view
   controller will be automatically determined and used.
   @param handler the callback.

   Use this method when you need to reathorize your app's access to user data via the Graph API.
   You should only call this after access has expired.
   You should provide as much context to the user as possible as to why you need to reauthorize the access, the
   scope of access being reathorized, and what added value your app provides when the access is reathorized.
   You can inspect the `result.declinedPermissions` to determine if you should provide more information to the
   user based on any declined permissions.

   @warning This method will reauthorize using a `LoginConfiguration` with `FBSDKLoginTracking` set to `.enabled`.
   @warning This method will present UI the user. You typically should call this if `AccessToken.isDataAccessExpired`
   is true.
   */
  @objc(reauthorizeDataAccess:handler:)
  public func reauthorizeDataAccess(
    from viewController: UIViewController,
    handler: @escaping LoginManagerLoginResultBlock
  ) {
    guard
      validateLoginStartState(),
      let dependencies = try? getDependencies()
    else { return }

    guard dependencies.accessTokenWallet.current != nil else {
      let message = "Must have an access token for which to reauthorize data access"
      let error = dependencies.errorFactory.error(
        domain: LoginErrorDomain,
        code: LoginError.missingAccessToken.rawValue,
        message: message,
        underlyingError: nil
      )

      Logger.singleShotLogEntry(.developerErrors, logEntry: message)
      return handler(nil, error)
    }

    let configuration = LoginConfiguration(
      permissions: [], // Don't need to pass permissions for data reauthorization.
      tracking: .enabled,
      messengerPageId: nil,
      authType: .reauthorize
    )

    commonLogIn(from: fromViewController, configuration: configuration, completion: handler)
  }

  // MARK: - Logging Out

  /**
   Logs the user out

   This nils out the singleton instances of `AccessToken`, `AuthenticationToken` and `Profle`.

   @note This is only a client side logout. It will not log the user out of their Facebook account.
   */
  @objc(logOut)
  public func logOut() {
    guard let dependencies = try? getDependencies() else { return }

    dependencies.accessTokenWallet.current = nil
    dependencies.authenticationTokenWallet.current = nil
    dependencies.profileProvider.current = nil
  }

  // MARK: - Helpers

  private func handleImplicitCancelOfLogIn() {
    let result = LoginManagerLoginResult(
      token: nil,
      authenticationToken: nil,
      isCancelled: true,
      grantedPermissions: [],
      declinedPermissions: []
    )

    result.addLoggingExtra(true, forKey: "implicit_cancel")
    invokeHandler(result: result)
  }

  private func validateLoginStartState() -> Bool {
    switch state {
    case .start:
      if usedSafariSession {
        // Using SFAuthenticationSession makes an interstitial dialog that blocks the app, but in certain situations
        // such as screen lock it can be dismissed and have the control returned to the app without invoking the
        // completionHandler. In this case, the view controller has the control back and tried to reinvoke the login.
        // This is acceptable behavior and we should pop up the dialog again
        return true
      } else {
        let message = """
          ** WARNING: You are trying to start a login while a previous login has not finished yet. This is unsupported \
          behavior. You should wait until the previous login handler gets called to start a new login.
          """

        Logger.singleShotLogEntry(.developerErrors, logEntry: message)
        return false
      }

    case .performingLogin:
      handleImplicitCancelOfLogIn()
      return true

    case .idle:
      state = .start
      return true
    }
  }

  func completeAuthentication(parameters: _LoginCompletionParameters, expectChallenge: Bool) {
    let isCancelled = (parameters.accessTokenString == nil)
      && (parameters.authenticationToken == nil)

    var error = parameters.error

    if expectChallenge,
       !isCancelled,
       error == nil {
      error = verifyChallenge(with: parameters)
    }

    storeExpectedChallenge(nil)

    var result: LoginManagerLoginResult?

    if error == nil {
      if !isCancelled {
        result = getSuccessResult(from: parameters)

        if result?.token != nil,
           let accessToken = self.accessTokenWallet?.current {
          // In a reauthentication, short circuit and let the login handler be called when the validation finishes.
          return validateReauthentication(accessToken: accessToken, loginResult: result)
        }
      } else {
        result = getCancelledResult(from: parameters)
      }
    }

    setGlobalProperties(parameters: parameters, loginResult: result)

    invokeHandler(result: result, error: error)
  }

  private func setGlobalProperties(parameters: _LoginCompletionParameters, loginResult: LoginManagerLoginResult?) {
    guard let dependencies = try? getDependencies() else { return }

    let hasNewAuthenticationToken = (parameters.authenticationToken != nil)
    let hasNewOrUpdatedAccessToken = (loginResult?.token != nil)

    guard hasNewAuthenticationToken || hasNewOrUpdatedAccessToken else {
      // Assume cancellation. Don't do anything
      return
    }

    dependencies.authenticationTokenWallet.current = parameters.authenticationToken
    dependencies.accessTokenWallet.current = loginResult?.token
    dependencies.profileProvider.current = parameters.profile
  }

  // Returns an error if a stored challenge cannot be obtained from the completion parameters
  private func verifyChallenge(with completionParameters: _LoginCompletionParameters) -> Error? {
    let expectedChallenge = loadExpectedChallenge()?.replacingOccurrences(of: "+", with: " ")

    if expectedChallenge != completionParameters.challenge {
      return NSError(domain: LoginErrorDomain, code: LoginError.badChallengeString.rawValue)
    } else {
      return nil
    }
  }

  private func invokeHandler(
    result: LoginManagerLoginResult? = nil,
    error: Error? = nil
  ) {
    logger?.endLogin(with: result, error: error as NSError?)
    logger?.endSession()
    logger?.postLoginHeartbeat()
    logger = nil
    state = .idle

    guard let handlerBeforeInvocation = handler else { return }

    handlerBeforeInvocation(result, error)

    if let handlerAfterInvocation = handler,
       handlerBeforeInvocation == handlerAfterInvocation {
      handler = nil
    } else {
      let message = """
          ** WARNING: You are requesting permissions inside the completion block of an existing login. \
          This is unsupported behavior. You should request additional permissions only when they are needed, such as \
          requesting for publish_actions when the user performs a sharing action.
          """
      Logger.singleShotLogEntry(.developerErrors, logEntry: message)
    }
  }

  func logInParameters(
    configuration: LoginConfiguration?,
    loggingToken: String?,
    authenticationMethod: String
  ) -> [String: String]? {
    // Making sure configuration is not nil in case this method gets called
    // internally without specifying a configuration.
    guard let dependencies = try? getDependencies() else { return nil }

    guard let configuration = configuration else {
      let error = dependencies.errorFactory.error(
        code: LoginError.unknown.rawValue,
        userInfo: nil,
        message: "Unable to perform login.",
        underlyingError: nil
      )
      invokeHandler(error: error)
      return nil
    }

    dependencies.internalUtility.validateURLSchemes()

    let cbtInMilliseconds = round(1000 * Date().timeIntervalSince1970)
    let nullableParameters: [String: String?] = [
      "client_id": dependencies.settings.appID,
      "display": "touch",
      "sdk": "ios",
      "return_scopes": "true",
      "sdk_version": FBSDK_VERSION_STRING,
      "fbapp_pres": NSNumber(value: dependencies.internalUtility.isFacebookAppInstalled).stringValue,
      "auth_type": configuration.authType?.rawValue,
      "logging_token": loggingToken,
      "cbt": String(cbtInMilliseconds),
      "ies": NSNumber(value: dependencies.settings.isAutoLogAppEventsEnabled).stringValue,
      "local_client_id": dependencies.settings.appURLSchemeSuffix,
      "default_audience": _LoginUtility.string(forAudience: defaultAudience),
    ]
    var parameters = nullableParameters.compactMapValues { $0 }

    var permissions = configuration.requestedPermissions
    if let openIDPermission = FBPermission(string: "openid") {
      permissions.insert(openIDPermission)
    }
    parameters["scope"] = permissions.map(\.value).joined(separator: ",")

    if let messengerPageID = configuration.messengerPageId {
      parameters["messenger_page_id"] = messengerPageID
    }

    if let redirectURL = try? dependencies.internalUtility.appURL(
      withHost: "authorize",
      path: "",
      queryParameters: [:]
    ) {
      parameters["redirect_uri"] = redirectURL.absoluteString
    }

    let expectedChallenge = getStringForChallenge()
    let encodedChallenge = expectedChallenge.flatMap(Utility.encode(urlString:))
    let state: [String: Any] = ["challenge": encodedChallenge ?? NSNull()]
    if let clientState = _LoginManagerLogger.clientStateFor(
      authMethod: authenticationMethod,
      andExistingState: state,
      logger: logger
    ) {
      parameters["state"] = clientState
    }
    storeExpectedChallenge(expectedChallenge)

    switch configuration.tracking {
    case .limited:
      parameters["response_type"] = "id_token,graph_domain"
      parameters["tp"] = "ios_14_do_not_track"

    case .enabled:
      parameters["response_type"] = "id_token,token_or_nonce,signed_request,graph_domain"
      parameters["code_challenge"] = configuration.codeVerifier.challenge
      parameters["code_challenge_method"] = "S256"
      storeExpectedCodeVerifier(configuration.codeVerifier)
    }

    parameters["nonce"] = configuration.nonce
    storeExpectedNonce(configuration.nonce)

    let values = ["init": MonotonicTimer().getCurrentSeconds()]
    if let timestamp = try? BasicUtility.jsonString(for: values) {
      parameters["e2e"] = timestamp
    }

    return parameters
  }

  private func getStringForChallenge() -> String? {
    fb_randomString(Self.clientStateChallengeLength)?
      .replacingOccurrences(of: "+", with: "=")
  }

  func validateReauthentication(accessToken: AccessToken, loginResult: LoginManagerLoginResult?) {
    guard let dependencies = try? getDependencies() else { return }

    let request = dependencies.graphRequestFactory.createGraphRequest(
      withGraphPath: "me",
      parameters: ["fields": ""],
      tokenString: loginResult?.token?.tokenString,
      httpMethod: nil,
      flags: [.doNotInvalidateTokenOnError, .disableErrorRecovery]
    )

    request.start { [self] _, anyResult, error in
      guard
        let result = anyResult as? [String: Any],
        let actualID = result["id"] as? String,
        accessToken.userID == actualID
      else {
        let wrappedError = dependencies.errorFactory.error(
          domain: LoginErrorDomain,
          code: LoginError.userMismatch.rawValue,
          message: nil,
          underlyingError: error
        )
        return invokeHandler(error: wrappedError)
      }

      dependencies.accessTokenWallet.current = loginResult?.token
      invokeHandler(result: loginResult)
    }
  }

  private typealias BrowserLoginSuccessBlock = (_ didOpen: Bool, _ error: Error?) -> Void

  private func performBrowserLogIn(handler browserLoginHandler: BrowserLoginSuccessBlock?) {
    guard let dependencies = try? getDependencies() else { return }

    let urlScheme = "fb\(self.settings?.appID ?? "")\(self.settings?.appURLSchemeSuffix ?? "")"
    logger?.willAttemptAppSwitchingBehaviorWith(urlScheme: urlScheme)
    let serverConfigurationProvider = ServerConfigurationProvider()
    let shouldUseSafariViewController = serverConfigurationProvider.useSafariViewController(forDialogName: "login")
    let authenticationMethod = shouldUseSafariViewController
      ? LoggerAuthenticationMethod.safariViewController
      : LoggerAuthenticationMethod.browser

    logger?.startWith(authMethod: authenticationMethod)

    var potentialError: Error?
    var authenticationURL: URL?
    let loginParameters = logInParameters(
      configuration: configuration,
      loggingToken: serverConfigurationProvider.loggingToken,
      authenticationMethod: authenticationMethod
    )

    if let parameters = loginParameters,
       parameters["redirect_uri"] != nil {
      do {
        authenticationURL = try dependencies.internalUtility.facebookURL(
          withHostPrefix: "m.",
          path: Self.oAuthPath,
          queryParameters: parameters
        )
      } catch {
        potentialError = error
      }
    }

    let loginHandler = browserLoginHandler ?? { _, _ in }

    guard let url = authenticationURL else {
      let error = potentialError ?? dependencies.errorFactory.error(
        code: LoginError.unknown.rawValue,
        message: "Failed to construct OAuth browser url",
        underlyingError: nil
      )

      return loginHandler(false, error)
    }

    if shouldUseSafariViewController {
      // Note based on above, authURL must be a http scheme. If that changes, add a guard, otherwise SFVC can throw
      usedSafariSession = true
      dependencies.urlOpener.openURLWithSafariViewController(
        url: url,
        sender: self,
        from: fromViewController,
        handler: loginHandler
      )
    } else {
      dependencies.urlOpener.open(url, sender: self, handler: loginHandler)
    }
  }

  private func getCancelledResult(from parameters: _LoginCompletionParameters) -> LoginManagerLoginResult {
    var declinedPermissions = Set<String>()
    if self.accessTokenWallet?.current != nil {
      // Always include the list of declined permissions from this login request
      // if an access token is already cached by the SDK
      declinedPermissions = FBPermission.rawPermissions(from: parameters.declinedPermissions ?? [])
    }

    return LoginManagerLoginResult(
      token: nil,
      authenticationToken: nil,
      isCancelled: true,
      grantedPermissions: [],
      declinedPermissions: declinedPermissions
    )
  }

  private func getSuccessResult(from parameters: _LoginCompletionParameters) -> LoginManagerLoginResult {
    // Recent permissions are largely based on the existence of an access token.
    // Without an access token the 'recent' permissions will match the
    // intersection of the granted permissions and the requested permissions.
    // This is important because we want to create a result that accurately reflects
    // the currently-granted permissions even when there is no access token.
    guard
      let recentlyGrantedPermissions = parameters.permissions.flatMap(getRecentlyGrantedPermissions(from:)),
      !recentlyGrantedPermissions.isEmpty
    else {
      return getCancelledResult(from: parameters)
    }

    let recentlyDeclinedPermissions = getRecentlyDeclinedPermissions(from: parameters.declinedPermissions ?? [])

    let rawGrantedPermissions = FBPermission.rawPermissions(from: parameters.permissions ?? [])
    let rawDeclinedPermissions = FBPermission.rawPermissions(from: parameters.declinedPermissions ?? [])
    let rawRecentlyGrantedPermissions = FBPermission.rawPermissions(from: recentlyGrantedPermissions)
    let rawRecentlyDeclinedPermissions = FBPermission.rawPermissions(from: recentlyDeclinedPermissions)

    var accessToken: AccessToken?
    if let accessTokenString = parameters.accessTokenString {
      accessToken = AccessToken(
        tokenString: accessTokenString,
        permissions: Array(rawGrantedPermissions),
        declinedPermissions: Array(rawDeclinedPermissions),
        expiredPermissions: [],
        appID: parameters.appID ?? "",
        userID: parameters.userID ?? "",
        expirationDate: parameters.expirationDate,
        refreshDate: Date(),
        dataAccessExpirationDate: parameters.dataAccessExpirationDate
      )
    }

    return LoginManagerLoginResult(
      token: accessToken,
      authenticationToken: parameters.authenticationToken,
      isCancelled: false,
      grantedPermissions: rawRecentlyGrantedPermissions,
      declinedPermissions: rawRecentlyDeclinedPermissions
    )
  }

  func getRecentlyGrantedPermissions(from grantedPermissions: Set<FBPermission>) -> Set<FBPermission> {
    guard
      let previous = self.accessTokenWallet?.current?.permissions,
      !previous.isEmpty,
      let requested = requestedPermissions,
      !requested.isEmpty
    else { return grantedPermissions }

    // If there were no requested permissions for this auth, or no previously granted permissions, treat all
    // permissions as recently granted.
    // Otherwise this is a reauthorization, so recentlyGranted should be a subset of what was requested.
    return grantedPermissions.intersection(requested)
  }

  func getRecentlyDeclinedPermissions(from declinedPermissions: Set<FBPermission>) -> Set<FBPermission> {
    let recentlyDeclinedPermissions = requestedPermissions ?? []
    return recentlyDeclinedPermissions.intersection(declinedPermissions)
  }

  // MARK: - Keychain Storage

  private func storeExpectedChallenge(_ challenge: String?) {
    guard let keychainStore = self.keychainStore else { return }

    let accessibility = DynamicFrameworkLoaderProxy
      .loadkSecAttrAccessibleAfterFirstUnlockThisDeviceOnly()
      .takeRetainedValue()

    keychainStore.setString(
      challenge,
      forKey: Keys.expectedChallenge,
      accessibility: accessibility
    )
  }

  private func loadExpectedChallenge() -> String? {
    self.keychainStore?.string(forKey: Keys.expectedChallenge)
  }

  func storeExpectedNonce(_ nonce: String?) {
    let accessibility = DynamicFrameworkLoaderProxy
      .loadkSecAttrAccessibleAfterFirstUnlockThisDeviceOnly()
      .takeRetainedValue()

    self.keychainStore?.setString(
      nonce,
      forKey: Keys.expectedNonce,
      accessibility: accessibility
    )
  }

  private func loadExpectedNonce() -> String? {
    self.keychainStore?.string(forKey: Keys.expectedNonce)
  }

  private func storeExpectedCodeVerifier(_ codeVerifier: CodeVerifier?) {
    let accessibility = DynamicFrameworkLoaderProxy
      .loadkSecAttrAccessibleAfterFirstUnlockThisDeviceOnly()
      .takeRetainedValue()

    self.keychainStore?.setString(
      codeVerifier?.value,
      forKey: Keys.expectedCodeVerifier,
      accessibility: accessibility
    )
  }

  private func loadExpectedCodeVerifier() -> String? {
    self.keychainStore?.string(forKey: Keys.expectedCodeVerifier)
  }
}

extension LoginManager: URLOpening {
  public func application(
    _ application: UIApplication?,
    open url: URL?,
    sourceApplication: String?,
    annotation: Any?
  ) -> Bool {
    guard let url = url else { return false }

    let isFacebookURL = canOpen(
      url,
      for: application,
      sourceApplication: sourceApplication,
      annotation: annotation
    )

    if !isFacebookURL,
       isPerformingLogin {
      handleImplicitCancelOfLogIn()
    }

    guard
      isFacebookURL,
      let dependencies = try? getDependencies()
    else { return false }

    let urlParameters = _LoginUtility.queryParams(fromLoginURL: url) ?? [:]
    let completer = dependencies.loginCompleterFactory.createLoginCompleter(
      urlParameters: urlParameters,
      appID: dependencies.settings.appID ?? ""
    )

    // Any necessary strong reference is maintained by the FBSDKLoginURLCompleter handler
    completer.completeLogin(
      nonce: loadExpectedNonce(),
      codeVerifier: loadExpectedCodeVerifier()
    ) { [self] parameters in
      if let configuration = configuration,
         logger == nil {
        logger = _LoginManagerLogger(
          parameters: urlParameters,
          tracking: configuration.tracking
        )
      }

      completeAuthentication(parameters: parameters, expectChallenge: true)
    }

    storeExpectedNonce(nil)
    storeExpectedCodeVerifier(nil)

    return true
  }

  public func canOpen(
    _ url: URL,
    for application: UIApplication?,
    sourceApplication: String?,
    annotation: Any?
  ) -> Bool {
    // Verify the URL is intended as a callback for the SDK's login
    guard
      let scheme = url.scheme,
      let host = url.host
    else { return false }

    return scheme.hasPrefix("fb\(self.settings?.appID ?? "")")
      && host == "authorize"
  }

  public func applicationDidBecomeActive(_ application: UIApplication) {
    if isPerformingLogin {
      handleImplicitCancelOfLogIn()
    }
  }

  public func isAuthenticationURL(_ url: URL) -> Bool {
    url.path.hasSuffix(Self.oAuthPath)
  }

  public func shouldStopPropagation(of url: URL) -> Bool {
    guard
      let scheme = url.scheme,
      let host = url.host
    else { return false }

    return scheme.hasPrefix("fb\(self.settings?.appID ?? "")")
      && host == "no-op"
  }
}

extension LoginManager: LoginProviding {}

extension LoginManager: DependentAsInstance {
  struct InstanceDependencies {
    var accessTokenWallet: AccessTokenProviding.Type
    var authenticationTokenWallet: AuthenticationTokenProviding.Type
    var errorFactory: ErrorCreating
    var graphRequestFactory: GraphRequestFactoryProtocol
    var internalUtility: URLHosting & AppURLSchemeProviding & AppAvailabilityChecker
    var keychainStore: KeychainStoreProtocol
    var loginCompleterFactory: LoginCompleterFactoryProtocol
    var profileProvider: ProfileProviding.Type
    var settings: SettingsProtocol
    var urlOpener: URLOpener
  }
}

#endif
