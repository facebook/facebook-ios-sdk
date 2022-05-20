/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !os(tvOS)

import FBSDKCoreKit
import UIKit

/**
 A button that initiates a log in or log out flow upon tapping.

 `LoginButton` works with `AccessToken.current` to determine what to display,
 and automatically starts authentication when tapped (i.e., you do not need to manually subscribe action targets).

 Like `LoginManager`, you should make sure your app delegate is connected to `ApplicationDelegate`
 in order for the button's delegate to receive messages.

 `LoginButton` has a fixed height of 30 pixels, but you may change the width.
 Initializing the button with `nil` frame will size the button to its minimum frame.
 */
@objcMembers
@objc(FBSDKLoginButton)
public final class FBLoginButton: FBButton {

  /// The default audience to use, if publish permissions are requested at login time.
  public var defaultAudience: DefaultAudience {
    get { loginProvider.defaultAudience }
    set { loginProvider.defaultAudience = newValue }
  }

  /// Gets or sets the delegate.
  @IBOutlet public weak var delegate: LoginButtonDelegate? // swiftlint:disable:this private_outlet

  /**
   The permissions to request.
   To provide the best experience, you should minimize the number of permissions you request, and only ask for them when needed.
   For example, do not ask for "user_location" until you the information is actually used by the app.

   Note this is converted to NSSet and is only
   an NSArray for the convenience of literal syntax.

   See [the permissions guide]( https://developers.facebook.com/docs/facebook-login/permissions/ ) for more details.
   */
  public var permissions: [String] = []

  /// Gets or sets the desired tooltip behavior.
  public var tooltipBehavior: FBLoginButton.TooltipBehavior = .automatic

  /// Gets or sets the desired tooltip color style.
  public var tooltipColorStyle: FBTooltipView.ColorStyle = .friendlyBlue

  /// Gets or sets the desired tracking preference to use for login attempts. Defaults to `.enabled`
  public var loginTracking: LoginTracking = .enabled

  /**
   Gets or sets an optional nonce to use for login attempts. A valid nonce must be a non-empty string without whitespace.
   An invalid nonce will not be set. Instead, default unique nonces will be used for login attempts.
   */
  public var nonce: String? {
    get {
      nonceValue
    }

    set {
      if let nonce = newValue,
         NonceValidator.isValid(nonce: nonce) {
        nonceValue = nonce
      } else {
        nonceValue = nil
        let msg = "Unable to set invalid nonce: \(String(describing: nonce)) on FBLoginButton"
        Logger.singleShotLogEntry(.developerErrors, logEntry: msg)
      }
    }
  }

  /// Gets or sets an optional page id to use for login attempts.
  public var messengerPageId: String?

  /// Gets or sets the login authorization type to use in the login request. Defaults to `rerequest`. Use `nil` to avoid
  /// requesting permissions that were previously denied.
  public var authType: LoginAuthType? = .rerequest

  /// The code verifier used in the PKCE process.
  /// If not provided, a code verifier will be randomly generated.
  public var codeVerifier = CodeVerifier()

  private var nonceValue: String?
  private var hasShownTooltipBubble = false

  var userID: String?
  var userName: String?
  var elementProvider: _UserInterfaceElementProviding = InternalUtility.shared
  var stringProvider: _UserInterfaceStringProviding = InternalUtility.shared
  var loginProvider: _LoginProviding = LoginManager()
  var graphRequestFactory: GraphRequestFactoryProtocol = GraphRequestFactory()

  var isAuthenticated: Bool {
    AccessToken.current != nil || AuthenticationToken.current != nil
  }

  /**
    Indicates the desired login tooltip behavior.
   */
  @objc(FBSDKLoginButtonTooltipBehavior)
  public enum TooltipBehavior: UInt {
    /** The default behavior. The tooltip will only be displayed if
     the app is eligible (determined by possible server round trip) */
    case automatic = 0

    /// Force display of the tooltip (typically for UI testing)
    case forceDisplay

    /** Force disable. In this case you can still exert more refined
     control by manually constructing a `FBSDKLoginTooltipView` instance. */
    case disable
  }

  private enum ViewGeometry {
    static let logoSize = 16.0
    static let logoLeftMargin = 6.0
    static let buttonHeight = 28.0
    static let rightMargin = 8.0
    static let paddingBetweenLogoTitle = 8.0
  }

  // MARK: - Initialization

  public override init(frame: CGRect) {
    super.init(frame: frame)
    configureButton()
  }

  required init?(coder: NSCoder) {
    super.init(coder: coder)
    configureButton()
  }

  convenience init(
    frame: CGRect = .zero,
    elementProvider: _UserInterfaceElementProviding,
    stringProvider: _UserInterfaceStringProviding,
    loginProvider: _LoginProviding,
    graphRequestFactory: GraphRequestFactoryProtocol
  ) {
    self.init(frame: frame)
    self.elementProvider = elementProvider
    self.stringProvider = stringProvider
    self.loginProvider = loginProvider
    self.graphRequestFactory = graphRequestFactory
  }

  /**
   Create a new `LoginButton` with a given optional frame and read permissions.

   - Parameter frame: Optional frame to initialize with. Default: `nil`, which uses a default size for the button.
   - Parameter permissions: Array of read permissions to request when logging in.
   */
  convenience init(frame: CGRect = .zero, permissions: [Permission] = [.publicProfile]) {
    self.init(frame: frame)
    self.permissions = permissions.map { $0.name }
  }

  private func configureButton() {
    let logInTitle = shortLogInTitle()
    let logOutTitle = logOutTitle()

    configure(
      with: nil,
      title: logInTitle,
      backgroundColor: backgroundColor,
      highlightedColor: nil,
      selectedTitle: logOutTitle,
      selectedIcon: nil,
      selectedColor: backgroundColor,
      selectedHighlightedColor: nil
    )

    titleLabel?.textAlignment = .center
    let heightConstraint = heightAnchor.constraint(equalToConstant: ViewGeometry.buttonHeight)
    heightConstraint.isActive = true
    addConstraint(heightConstraint)

    initializeContent()
    addTarget(self, action: #selector(buttonPressed), for: .touchUpInside)
    addNotificationObservers()
  }

  // MARK: - UIView

  public override func didMoveToWindow() {
    super.didMoveToWindow()

    if window != nil,
       tooltipBehavior == .forceDisplay || !hasShownTooltipBubble {
      showTooltipIfNeeded()
      hasShownTooltipBubble = true
    }
  }

  // MARK: - Layout

  public override func imageRect(forContentRect contentRect: CGRect) -> CGRect {
    CGRect(
      x: ViewGeometry.logoLeftMargin,
      y: contentRect.midY - ViewGeometry.logoSize / 2,
      width: ViewGeometry.logoSize,
      height: ViewGeometry.logoSize
    )
  }

  public override func titleRect(forContentRect contentRect: CGRect) -> CGRect {
    guard
      !isHidden,
      !bounds.isEmpty
    else { return .zero }

    let imageRect = imageRect(forContentRect: contentRect)
    let titleX = imageRect.maxX + ViewGeometry.paddingBetweenLogoTitle

    return CGRect(
      x: titleX,
      y: 0,
      width: contentRect.width - titleX - ViewGeometry.rightMargin,
      height: contentRect.height
    )
  }

  public override func layoutSubviews() {
    let size = bounds.size
    let longTitleSize = sizeThatFits(size, title: longLogInTitle())
    let title = longTitleSize.width <= size.width ? longLogInTitle() : shortLogInTitle()
    if title != self.title(for: .normal) {
      setTitle(title, for: .normal)
    }
    super.layoutSubviews()
  }

  public override func sizeThatFits(_ size: CGSize) -> CGSize {
    guard
      !isHidden,
      let titleLabel = titleLabel,
      let font = titleLabel.font
    else { return .zero }

    let selectedSize = textSize(
      forText: logOutTitle(),
      font: font,
      constrainedSize: size,
      lineBreakMode: titleLabel.lineBreakMode
    )

    var normalSize = textSize(
      forText: longLogInTitle(),
      font: font,
      constrainedSize: size,
      lineBreakMode: titleLabel.lineBreakMode
    )

    if normalSize.width > size.width {
      normalSize = textSize(
        forText: shortLogInTitle(),
        font: font,
        constrainedSize: size,
        lineBreakMode: titleLabel.lineBreakMode
      )
    }

    let titleWidth = max(normalSize.width, selectedSize.width)
    let buttonWidth = ViewGeometry.logoLeftMargin
      + ViewGeometry.logoSize
      + ViewGeometry.paddingBetweenLogoTitle
      + titleWidth
      + ViewGeometry.rightMargin

    return CGSize(width: buttonWidth, height: ViewGeometry.buttonHeight)
  }

  // MARK: - Notifications

  private func addNotificationObservers() {
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(profileDidChange),
      name: .ProfileDidChange,
      object: nil
    )
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(accessTokenDidChange),
      name: .AccessTokenDidChange,
      object: nil
    )
  }

  func accessTokenDidChange(_ notification: Notification) {
    guard let userInfo = notification.userInfo else { return }

    if userInfo[AccessTokenDidChangeUserIDKey] != nil || userInfo[AccessTokenDidExpireKey] != nil {
      updateContentForAccessToken()
    }
  }

  func profileDidChange(_ notification: Notification) {
    updateContentForUser(.current)
  }

  // MARK: - Button Configuration

  func buttonPressed(_ sender: Any) {
    if isAuthenticated {
      if loginTracking != .limited {
        logTapEvent(withEventName: .loginButtonDidTap, parameters: nil)
      }

      presentAlertViewController()
    } else {
      if let loginButtonWillLogin = delegate?.loginButtonWillLogin, !loginButtonWillLogin(self) {
        return
      }

      logInUser()
    }
  }

  func makeLoginConfiguration() -> LoginConfiguration? {
    let nonce = nonce ?? UUID().uuidString
    return LoginConfiguration(
      permissions: Set(permissions.map(Permission.init(stringLiteral:))),
      tracking: loginTracking,
      nonce: nonce,
      messengerPageId: messengerPageId,
      authType: authType,
      codeVerifier: codeVerifier
    )
  }

  private func logInUser() {

    let loginConfiguration = makeLoginConfiguration()

    if loginTracking == .enabled {
      logTapEvent(withEventName: .loginButtonDidTap, parameters: nil)
    }

    if let loginConfiguration = loginConfiguration {
      loginProvider.__logIn(
        from: elementProvider.viewController(for: self),
        configuration: loginConfiguration
      ) { result, error in
        self.delegate?.loginButton(self, didCompleteWith: result, error: error)
      }
    }
  }

  private func presentAlertViewController() {
    let title: String

    if let userName = userName {
      let localizedFormatString = NSLocalizedString(
        "LoginButton.LoggedInAs",
        tableName: "FacebookSDK",
        bundle: stringProvider.bundleForStrings,
        value: "Logged in as %@",
        comment: "The format string for the FBLoginButton label when the user is logged in"
      )
      title = String.localizedStringWithFormat(localizedFormatString, userName)
    } else {
      let localizedLoggedIn = NSLocalizedString(
        "LoginButton.LoggedIn",
        tableName: "FacebookSDK",
        bundle: stringProvider.bundleForStrings,
        value: "Logged in using Facebook",
        comment: "The fallback string for the FBLoginButton label when the user name is not available yet"
      )
      title = localizedLoggedIn
    }

    let cancelTitle = NSLocalizedString(
      "LoginButton.CancelLogout",
      tableName: "FacebookSDK",
      bundle: stringProvider.bundleForStrings,
      value: "Cancel",
      comment: "The label for the FBLoginButton action sheet to cancel logging out"
    )

    let logOutTitle = NSLocalizedString(
      "LoginButton.ConfirmLogOut",
      tableName: "FacebookSDK",
      bundle: stringProvider.bundleForStrings,
      value: "Log Out",
      comment: "The label for the FBLoginButton action sheet to confirm logging out"
    )

    let alertController = UIAlertController(title: title, message: nil, preferredStyle: .actionSheet)
    alertController.popoverPresentationController?.sourceView = self
    alertController.popoverPresentationController?.sourceRect = bounds

    let cancel = UIAlertAction(title: cancelTitle, style: .cancel, handler: nil)
    let logout = UIAlertAction(title: logOutTitle, style: .destructive) { _ in
      self.logout()
    }

    alertController.addAction(cancel)
    alertController.addAction(logout)

    let topMostViewController = elementProvider.topMostViewController()
    topMostViewController?.present(alertController, animated: true)
  }

  private func logOutTitle() -> String {
    NSLocalizedString(
      "LoginButton.LogOut",
      tableName: "FacebookSDK",
      bundle: stringProvider.bundleForStrings,
      value: "Log out",
      comment: "The label for the FBLoginButton when the user is currently logged in"
    )
  }

  private func longLogInTitle() -> String {
    NSLocalizedString(
      "LoginButton.LogInContinue",
      tableName: "FacebookSDK",
      bundle: stringProvider.bundleForStrings,
      value: "Continue with Facebook",
      comment: "The long label for the FBLoginButton when the user is currently logged out"
    )
  }

  private func shortLogInTitle() -> String {
    NSLocalizedString(
      "LoginButton.LogIn",
      tableName: "FacebookSDK",
      bundle: stringProvider.bundleForStrings,
      value: "Log in",
      comment: "The short label for the FBLoginButton when the user is currently logged out"
    )
  }

  private func showTooltipIfNeeded() {
    guard
      !isAuthenticated,
      tooltipBehavior != .disable
    else { return }

    let tooltipView = FBLoginTooltipView()
    tooltipView.colorStyle = tooltipColorStyle

    if tooltipBehavior == .forceDisplay {
      tooltipView.shouldForceDisplay = true
    }

    tooltipView.present(from: self)
  }

  // MARK: - Content

  // On initial setting of button state. We want to update the button's user
  // information using the most comprehensive available.
  // If access token is available use that.
  // If only profile is available, use that.
  func initializeContent() {
    if AccessToken.current != nil {
      updateContentForAccessToken()
    } else if let profile = Profile.current {
      updateContentForUser(profile)
    } else {
      isSelected = false
    }
  }

  func updateContentForAccessToken() {
    let accessTokenIsValid = AccessToken.isCurrentAccessTokenActive
    isSelected = accessTokenIsValid

    if accessTokenIsValid,
       AccessToken.current?.userID != userID {
      fetchAndSetContent()
    }
  }

  func fetchAndSetContent() {
    let request = graphRequestFactory.createGraphRequest(
      withGraphPath: "me",
      parameters: ["fields": "id,name"],
      flags: .disableErrorRecovery
    )

    request.start { _, result, error in
      guard
        let dict = result as? [String: String],
        let userID = dict["id"],
        error == nil,
        let currentUserID = AccessToken.current?.userID,
        currentUserID == userID
      else { return }

      self.userName = dict["name"] ?? ""
      self.userID = userID
    }
  }

  func updateContentForUser(_ profile: Profile?) {
    guard let profile = profile else {
      isSelected = false
      return
    }

    isSelected = true

    if userInformationDoesNotMatch(profile) {
      userName = profile.name ?? ""
      userID = profile.userID
    }
  }

  private func userInformationDoesNotMatch(_ profile: Profile) -> Bool {
    profile.userID != userID || profile.name != userName
  }

  func logout() {
    loginProvider.logOut()
    delegate?.loginButtonDidLogOut(self)
  }
}

#endif
