// (c) Meta Platforms, Inc. and affiliates. Confidential and proprietary.

import FBSDKCoreKit
import FBSDKLoginKit
import UIKit

class SwiftLoginViewController: LoginViewController, LoginButtonDelegate {
  @IBOutlet var loginManagerButton: UIButton! {
    didSet {
      updateLoginButton()
    }
  }

  @IBOutlet var loginButton: FBLoginButton!
  @IBOutlet var nonceTextField: UITextField!
  @IBOutlet var limitTrackingSwitch: UISwitch!
  @IBOutlet var defaultAudienceButton: UIButton!

  var defaultAudience: DefaultAudience = .friends

  var tracking: LoginTracking {
    limitTrackingSwitch.isOn ? .limited : .enabled
  }

  var configuration: LoginConfiguration? {
    let permissions = Set(selectedPermissions.compactMap { Permission(stringLiteral: $0) })

    if let nonce = nonceTextField.text, !nonce.isEmpty {
      return LoginConfiguration(permissions: permissions, tracking: tracking, nonce: nonce)
    } else {
      return LoginConfiguration(permissions: permissions, tracking: tracking)
    }
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    if #available(iOS 14, *) {
      configureDefaultAudienceButton()
    }
  }

  @available(iOS 14, *)
  func configureDefaultAudienceButton() {
    defaultAudienceButton.menu = UIMenu(children: [
      UIAction(title: "Friends", state: .on, handler: { _ in self.defaultAudience = .friends }),
      UIAction(title: "Only Me", handler: { _ in self.defaultAudience = .onlyMe }),
      UIAction(title: "Everyone", handler: { _ in self.defaultAudience = .everyone }),
    ])
    defaultAudienceButton.showsMenuAsPrimaryAction = true
    if #available(iOS 15, *) {
      defaultAudienceButton.changesSelectionAsPrimaryAction = true
    }
  }

  @IBAction func loginTapped() {
    let loginManager = LoginManager(defaultAudience: defaultAudience)

    if isLoggedIn() {
      loginManager.logOut()
      updateLoginButton()
      return
    }

    guard let validConfiguration = configuration else {
      Console.sharedInstance()?.addMessage(
        "Invalid Configuration. Using default configuration",
        notificationName: NSNotification.Name.ConsoleDidReportBug.rawValue
      )
      return
    }

    loginManager.logIn(
      viewController: self,
      configuration: validConfiguration
    ) { result in
      self.updateLoginButton()

      switch result {
      case .success:
        break
      case .cancelled:
        Console.sharedInstance()?.addMessage("Login Cancelled", notificationName: NSNotification.Name.ConsoleDidReportBug.rawValue)
      case let .failed(error):
        Console.sharedInstance()?.addMessage("Error: \(error)", notificationName: NSNotification.Name.ConsoleDidReportBug.rawValue)
      }
      self.showLoginDetails()
    }
  }

  func updateLoginButton() {
    let title = isLoggedIn() ? "Log Out" : "Log In With Facebook"
    loginManagerButton.setTitle(title, for: .normal)
  }

  // MARK: Login Button Delegate Methods

  func loginButtonWillLogin(_ loginButton: FBLoginButton) -> Bool {
    loginButton.permissions = selectedPermissions
    loginButton.loginTracking = tracking

    if let nonce = nonceTextField.text, !nonce.isEmpty {
      loginButton.nonce = nonce
    }

    loginButton.defaultAudience = defaultAudience

    return true
  }

  func loginButtonDidLogOut(_ loginButton: FBLoginButton) {
    Console.sharedInstance()?.addMessage(
      "Logged out",
      notificationName: NSNotification.Name.ConsoleDidAddMessage.rawValue
    )
    updateLoginButton()
  }

  func loginButton(
    _ loginButton: FBLoginButton,
    didCompleteWith result: LoginManagerLoginResult?,
    error: Error?
  ) {
    updateLoginButton()
    if let error = error {
      Console.sharedInstance()?.addMessage(
        "Error: \(error)",
        notificationName: NSNotification.Name.ConsoleDidReportBug.rawValue
      )
      return
    }

    if let validResult = result {
      showLoginDetails(
        for: validResult,
        requestedPermissions: selectedPermissions
      )
    } else {
      showLoginDetails()
    }
  }
}
