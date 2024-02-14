// (c) Meta Platforms, Inc. and affiliates. Confidential and proprietary.

import UIKit

import AppTrackingTransparency
import FBSDKCoreKit

class PrivacyToggleViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

  #if targetEnvironment(simulator)
  private let toggles: Array = ["iOS 14", "Event Collection Enabled", "IDFA Collection Enabled", "LAT Enabled", "Default ATE", "Set ATE", "Log Event", "Reset", "Publish Install", "Test Batch Request", "Get Custom Audience Third Party ID", "Test Codeless Indexing Session", "Request to Track"]
  #else
  private let toggles: Array = ["Event Collection Enabled", "IDFA Collection Enabled", "Default ATE", "Set ATE", "Log Event", "Reset", "Publish Install", "Test Batch Request", "Get Custom Audience Third Party ID", "Test Codeless Indexing Session", "Request to Track"]
  #endif

  private let consoleView: UITextView = .init()

  private let defaultStatusSC: UISegmentedControl = .init(items: ["Default On", "Default OFF", "Default Unspecified"])
  private let statusSC: UISegmentedControl = .init(items: ["On", "OFF", "Unspecified"])

  private let osVersionToggle: UISwitch = .init()
  private let eventCollectionToggle: UISwitch = .init()
  private let advertiserIDCollectionToggle: UISwitch = .init()
  private let LATToggle: UISwitch = .init()

  private let tableView: UITableView = .init()

  override func viewDidLoad() {
    super.viewDidLoad()

    title = "Privacy Toggle"

    tableView.rowHeight = 40
    tableView.register(UITableViewCell.self, forCellReuseIdentifier: "ToggleCell")
    tableView.delegate = self
    tableView.dataSource = self
    consoleView.layer.borderColor = UIColor.lightGray.cgColor
    consoleView.layer.borderWidth = 1
    consoleView.layer.cornerRadius = 3
    consoleView.isEditable = false
    defaultStatusSC.setTitleTextAttributes([NSAttributedString.Key.font: UIFont.systemFont(ofSize: 10)], for: .normal)
    defaultStatusSC.addTarget(self, action: #selector(PrivacyToggleViewController.selectDefaultAdvertisingTrackingStatus(sender:)), for: .valueChanged)
    statusSC.setTitleTextAttributes([NSAttributedString.Key.font: UIFont.systemFont(ofSize: 10)], for: .normal)
    statusSC.addTarget(self, action: #selector(PrivacyToggleViewController.selectAdvertisingTrackingStatus(sender:)), for: .valueChanged)
    osVersionToggle.addTarget(self, action: #selector(PrivacyToggleViewController.switchOsVersion(sender:)), for: .valueChanged)
    LATToggle.addTarget(self, action: #selector(PrivacyToggleViewController.setLATEnabled(sender:)), for: .valueChanged)

    // Set Accessibility ID
    consoleView.accessibilityIdentifier = "textview_console"

    reset()
    AppEvents.shared.flush()
    Settings.shared.enableLoggingBehavior(.appEvents)
    Settings.shared.enableLoggingBehavior(.networkRequests)
    AppEvents.shared.flushBehavior = .explicitOnly
    #if targetEnvironment(simulator)
    PrivacyTestUtils.swizzleOSVersionCheck()
    #else
    osVersionToggle.isEnabled = false
    LATToggle.isEnabled = false
    #endif
    PrivacyTestUtils.swizzleLogger(forConsole: consoleView)

    consoleView.frame = CGRect(x: 0, y: 44, width: view.frame.width, height: 200)
    tableView.frame = CGRect(x: 0, y: 244, width: view.frame.width, height: view.frame.height - 244)
    view.addSubview(consoleView)
    view.addSubview(tableView)
  }

  // MARK: View Management

  func numberOfSections(in tableView: UITableView) -> Int {
    1
  }

  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    toggles.count
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "ToggleCell", for: indexPath)
    cell.selectionStyle = .none
    #if targetEnvironment(simulator)
    switch indexPath.row {
    case 0:
      cell.accessoryType = .disclosureIndicator
      cell.textLabel?.text = toggles[indexPath.row]
      cell.accessoryView = osVersionToggle
      cell.accessibilityIdentifier = "cell_os"
    case 1:
      cell.accessoryType = .disclosureIndicator
      cell.textLabel?.text = toggles[indexPath.row]
      cell.accessoryView = eventCollectionToggle
      cell.accessibilityIdentifier = "cell_event_collection"
    case 2:
      cell.accessoryType = .disclosureIndicator
      cell.textLabel?.text = toggles[indexPath.row]
      cell.accessoryView = advertiserIDCollectionToggle
      cell.accessibilityIdentifier = "cell_advertiserid_collection"
    case 3:
      cell.accessoryType = .disclosureIndicator
      cell.textLabel?.text = toggles[indexPath.row]
      cell.accessoryView = LATToggle
      cell.accessibilityIdentifier = "cell_lat"
    case 4:
      cell.accessoryType = .disclosureIndicator
      cell.textLabel?.text = toggles[indexPath.row]
      defaultStatusSC.frame = CGRect(x: 0, y: 0, width: cell.frame.width - 90, height: cell.frame.height)
      cell.accessoryView = defaultStatusSC
      cell.accessibilityIdentifier = "cell_default_ate_status"
    case 5:
      cell.accessoryType = .disclosureIndicator
      cell.textLabel?.text = toggles[indexPath.row]
      statusSC.frame = CGRect(x: 0, y: 0, width: cell.frame.width - 90, height: cell.frame.height)
      cell.accessoryView = statusSC
      cell.accessibilityIdentifier = "cell_tracking_enabled"
    case 6:
      cell.layoutMargins = .zero
      cell.accessoryType = .none
      let button = UIButton(frame: CGRect(x: 20, y: 3, width: view.frame.width - 40, height: 34))
      button.backgroundColor = .systemBlue
      button.setTitle("Log Event", for: .normal)
      button.layer.cornerRadius = 5.0
      button.addTarget(self, action: #selector(PrivacyToggleViewController.logEvent), for: .touchUpInside)
      cell.accessoryView = button
      button.accessibilityIdentifier = "button_log_event"
    case 7:
      cell.layoutMargins = .zero
      cell.accessoryType = .none
      let button = UIButton(frame: CGRect(x: 20, y: 3, width: view.frame.width - 40, height: 34))
      button.backgroundColor = .systemBlue
      button.setTitle("Reset flags and console", for: .normal)
      button.layer.cornerRadius = 5.0
      button.addTarget(self, action: #selector(PrivacyToggleViewController.reset), for: .touchUpInside)
      cell.accessoryView = button
      button.accessibilityIdentifier = "button_reset"
    case 8:
      cell.layoutMargins = .zero
      cell.accessoryType = .none
      let button = UIButton(frame: CGRect(x: 20, y: 3, width: view.frame.width - 40, height: 34))
      button.backgroundColor = .systemBlue
      button.setTitle("Publish Install", for: .normal)
      button.layer.cornerRadius = 5.0
      button.addTarget(self, action: #selector(PrivacyToggleViewController.publishInstall), for: .touchUpInside)
      cell.accessoryView = button
      button.accessibilityIdentifier = "button_publish_install"
    case 9:
      cell.layoutMargins = .zero
      cell.accessoryType = .none
      let button = UIButton(frame: CGRect(x: 20, y: 3, width: view.frame.width - 40, height: 34))
      button.backgroundColor = .systemBlue
      button.setTitle("Test Batch Request", for: .normal)
      button.layer.cornerRadius = 5.0
      button.addTarget(self, action: #selector(PrivacyToggleViewController.testBatchRequest), for: .touchUpInside)
      cell.accessoryView = button
      button.accessibilityIdentifier = "button_test_batch_request"
    case 10:
      cell.layoutMargins = .zero
      cell.accessoryType = .none
      let button = UIButton(frame: CGRect(x: 20, y: 3, width: view.frame.width - 40, height: 34))
      button.backgroundColor = .systemBlue
      button.setTitle("Get Custom Audience Third Party ID", for: .normal)
      button.layer.cornerRadius = 5.0
      button.addTarget(self, action: #selector(PrivacyToggleViewController.testGetCustomAudienceThirdPartyID), for: .touchUpInside)
      cell.accessoryView = button
      button.accessibilityIdentifier = "button_get_custom_audience_third_party_id"
    case 11:
      cell.layoutMargins = .zero
      cell.accessoryType = .none
      let button = UIButton(frame: CGRect(x: 20, y: 3, width: view.frame.width - 40, height: 34))
      button.backgroundColor = .systemBlue
      button.setTitle("Test Codeless Indexing Session", for: .normal)
      button.layer.cornerRadius = 5.0
      button.addTarget(self, action: #selector(PrivacyToggleViewController.testCheckCodelessIndexingSession), for: .touchUpInside)
      cell.accessoryView = button
      button.accessibilityIdentifier = "button_test_codeless_indexing"
    case 12:
      cell.layoutMargins = .zero
      cell.accessoryType = .none
      let button = UIButton(frame: CGRect(x: 20, y: 3, width: view.frame.width - 40, height: 34))
      button.backgroundColor = .systemBlue
      button.setTitle("Request to Track", for: .normal)
      button.layer.cornerRadius = 5.0
      button.addTarget(self, action: #selector(PrivacyToggleViewController.requestToTrack), for: .touchUpInside)
      cell.accessoryView = button
      button.accessibilityIdentifier = "button_request_to_track"
    default:
      cell.accessoryType = .disclosureIndicator
      cell.textLabel?.text = toggles[indexPath.row]
      cell.accessoryView = UISwitch()
    }
    #else
    switch indexPath.row {
    case 0:
      cell.accessoryType = .disclosureIndicator
      cell.textLabel?.text = toggles[indexPath.row]
      cell.accessoryView = eventCollectionToggle
      cell.accessibilityIdentifier = "cell_event_collection"
    case 1:
      cell.accessoryType = .disclosureIndicator
      cell.textLabel?.text = toggles[indexPath.row]
      cell.accessoryView = advertiserIDCollectionToggle
      cell.accessibilityIdentifier = "cell_advertiserid_collection"
    case 2:
      cell.accessoryType = .disclosureIndicator
      cell.textLabel?.text = toggles[indexPath.row]
      defaultStatusSC.frame = CGRect(x: 0, y: 0, width: cell.frame.width - 90, height: cell.frame.height)
      cell.accessoryView = defaultStatusSC
      cell.accessibilityIdentifier = "cell_default_ate_status"
    case 3:
      cell.accessoryType = .disclosureIndicator
      cell.textLabel?.text = toggles[indexPath.row]
      statusSC.frame = CGRect(x: 0, y: 0, width: cell.frame.width - 90, height: cell.frame.height)
      cell.accessoryView = statusSC
      cell.accessibilityIdentifier = "cell_tracking_enabled"
    case 4:
      cell.layoutMargins = .zero
      cell.accessoryType = .none
      let button = UIButton(frame: CGRect(x: 20, y: 3, width: view.frame.width - 40, height: 34))
      button.backgroundColor = .systemBlue
      button.setTitle("Log Event", for: .normal)
      button.layer.cornerRadius = 5.0
      button.addTarget(self, action: #selector(PrivacyToggleViewController.logEvent), for: .touchUpInside)
      cell.accessoryView = button
      button.accessibilityIdentifier = "button_log_event"
    case 5:
      cell.layoutMargins = .zero
      cell.accessoryType = .none
      let button = UIButton(frame: CGRect(x: 20, y: 3, width: view.frame.width - 40, height: 34))
      button.backgroundColor = .systemBlue
      button.setTitle("Reset flags and console", for: .normal)
      button.layer.cornerRadius = 5.0
      button.addTarget(self, action: #selector(PrivacyToggleViewController.reset), for: .touchUpInside)
      cell.accessoryView = button
      button.accessibilityIdentifier = "button_reset"
    case 6:
      cell.layoutMargins = .zero
      cell.accessoryType = .none
      let button = UIButton(frame: CGRect(x: 20, y: 3, width: view.frame.width - 40, height: 34))
      button.backgroundColor = .systemBlue
      button.setTitle("Publish Install", for: .normal)
      button.layer.cornerRadius = 5.0
      button.addTarget(self, action: #selector(PrivacyToggleViewController.publishInstall), for: .touchUpInside)
      cell.accessoryView = button
      button.accessibilityIdentifier = "button_publish_install"
    case 7:
      cell.layoutMargins = .zero
      cell.accessoryType = .none
      let button = UIButton(frame: CGRect(x: 20, y: 3, width: view.frame.width - 40, height: 34))
      button.backgroundColor = .systemBlue
      button.setTitle("Test Batch Request", for: .normal)
      button.layer.cornerRadius = 5.0
      button.addTarget(self, action: #selector(PrivacyToggleViewController.testBatchRequest), for: .touchUpInside)
      cell.accessoryView = button
      button.accessibilityIdentifier = "button_test_batch_request"
    case 8:
      cell.layoutMargins = .zero
      cell.accessoryType = .none
      let button = UIButton(frame: CGRect(x: 20, y: 3, width: view.frame.width - 40, height: 34))
      button.backgroundColor = .systemBlue
      button.setTitle("Get Custom Audience Third Party ID", for: .normal)
      button.layer.cornerRadius = 5.0
      button.addTarget(self, action: #selector(PrivacyToggleViewController.testGetCustomAudienceThirdPartyID), for: .touchUpInside)
      cell.accessoryView = button
      button.accessibilityIdentifier = "button_get_custom_audience_third_party_id"
    case 9:
      cell.layoutMargins = .zero
      cell.accessoryType = .none
      let button = UIButton(frame: CGRect(x: 20, y: 3, width: view.frame.width - 40, height: 34))
      button.backgroundColor = .systemBlue
      button.setTitle("Test Codeless Indexing Session", for: .normal)
      button.layer.cornerRadius = 5.0
      button.addTarget(self, action: #selector(PrivacyToggleViewController.testCheckCodelessIndexingSession), for: .touchUpInside)
      cell.accessoryView = button
      button.accessibilityIdentifier = "button_test_codeless_indexing"
    case 10:
      cell.layoutMargins = .zero
      cell.accessoryType = .none
      let button = UIButton(frame: CGRect(x: 20, y: 3, width: view.frame.width - 40, height: 34))
      button.backgroundColor = .systemBlue
      button.setTitle("Request to Track", for: .normal)
      button.layer.cornerRadius = 5.0
      button.addTarget(self, action: #selector(PrivacyToggleViewController.requestToTrack), for: .touchUpInside)
      cell.accessoryView = button
      button.accessibilityIdentifier = "button_request_to_track"
    default:
      cell.accessoryType = .disclosureIndicator
      cell.textLabel?.text = toggles[indexPath.row]
      cell.accessoryView = UISwitch()
    }
    #endif
    return cell
  }

  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    #if targetEnvironment(simulator)
    switch indexPath.row {
    case 0:
      PrivacyTestUtils.setIsIOS14(!osVersionToggle.isOn)
      osVersionToggle.setOn(!osVersionToggle.isOn, animated: true)
    case 1:
      PrivacyTestUtils.setFlag("_eventCollectionEnabled", value: !eventCollectionToggle.isOn)
      eventCollectionToggle.setOn(!eventCollectionToggle.isOn, animated: true)
    case 2:
      PrivacyTestUtils.setFlag("_advertiserIDCollectionEnabled", value: !advertiserIDCollectionToggle.isOn)
      advertiserIDCollectionToggle.setOn(!advertiserIDCollectionToggle.isOn, animated: true)
    case 3:
      PrivacyTestUtils.setIsLATEnabled(!LATToggle.isOn)
      LATToggle.setOn(!LATToggle.isOn, animated: true)
    default:
      break
    }
    #else
    switch indexPath.row {
    case 0:
      PrivacyTestUtils.setFlag("_eventCollectionEnabled", value: !eventCollectionToggle.isOn)
      eventCollectionToggle.setOn(!eventCollectionToggle.isOn, animated: true)
    case 1:
      PrivacyTestUtils.setFlag("_advertiserIDCollectionEnabled", value: !advertiserIDCollectionToggle.isOn)
      advertiserIDCollectionToggle.setOn(!advertiserIDCollectionToggle.isOn, animated: true)
    default:
      break
    }
    #endif
  }

  @objc func switchOsVersion(sender: UISwitch) {
    PrivacyTestUtils.setIsIOS14(sender.isOn)
  }

  @objc func setLATEnabled(sender: UISwitch) {
    PrivacyTestUtils.setIsLATEnabled(sender.isOn)
  }

  @objc func logEvent() {
    PrivacyTestUtils.setFlag("_eventCollectionEnabled", value: eventCollectionToggle.isOn)
    PrivacyTestUtils.setFlag("_advertiserIDCollectionEnabled", value: advertiserIDCollectionToggle.isOn)
    AppEvents.shared.logPurchase(amount: 100, currency: "USD")
    PrivacyTestUtils.logEventsState(toConsole: consoleView)
    AppEvents.shared.flush()
  }

  private func getTestThirdPartyIDRequest() -> GraphRequest? {
    let accessToken = AccessToken.current
    guard let thirdPartyIDRequest = AppEvents.shared.requestForCustomAudienceThirdPartyID(accessToken: accessToken) else {
      return nil
    }
    return thirdPartyIDRequest
  }

  private func getTestCheckCodelessIndexingSessionRequest() -> GraphRequest? {
    if !Settings.shared.isAdvertiserTrackingEnabled {
      return nil
    }
    guard let appID = Settings.shared.appID else {
      return nil
    }
    let parameters = [
      "device_session_id": UUID().uuidString,
      "extinfo": _CodelessIndexer.extInfo,
    ]
    let graphPath = "\(appID)/app_indexing_session"
    let codelessIndexingRequest = GraphRequest(
      graphPath: graphPath,
      parameters: parameters,
      httpMethod: .post
    )
    return codelessIndexingRequest
  }

  @objc func testBatchRequest() {
    PrivacyTestUtils.setFlag("_eventCollectionEnabled", value: eventCollectionToggle.isOn)
    PrivacyTestUtils.setFlag("_advertiserIDCollectionEnabled", value: advertiserIDCollectionToggle.isOn)
    let meRequest = GraphRequest(graphPath: "/me", parameters: [:])
    let permissionRequest = GraphRequest(graphPath: "/me/permissions", parameters: [:])
    let connectionFactory = GraphRequestConnectionFactory()
    let connection = connectionFactory.createGraphRequestConnection()
    connection.add(meRequest) { _, _, error in
      if let error = error {
        ConsoleReportBugWithFormattedMessage(
          "Received error in fetching user information in batch request: \(String(describing: error))"
        )
      } else {
        ConsoleSucceedWithFormattedMessage(
          "Successfully fetched user information in batch request"
        )
      }
    }
    connection.add(permissionRequest) { _, _, error in
      if let error = error {
        ConsoleReportBugWithFormattedMessage(
          "Received error in fetching user permissions in batch request: \(String(describing: error))"
        )
      } else {
        ConsoleSucceedWithFormattedMessage(
          "Successfully fetched user permissions in batch request"
        )
      }
    }
    if let thirdPartyIDRequest = getTestThirdPartyIDRequest() {
      connection.add(thirdPartyIDRequest) { _, result, error in
        if let error = error {
          ConsoleReportBugWithFormattedMessage(
            "Received error in fetching custom audience third party id in batch request: \(String(describing: error))"
          )
        } else {
          if let resultDict = result as? [String: Any] {
            ConsoleSucceedWithFormattedMessage(
              "Custom audience third party id fetched in batch request: \(resultDict)"
            )
          } else {
            ConsoleReportBugWithFormattedMessage(
              "Expected custom audience third party id batch request response result to be of type Dictionary but got \(type(of: result))"
            )
          }
        }
      }
    }
    connection.start()
  }

  @objc func testGetCustomAudienceThirdPartyID() {
    guard let thirdPartyIDRequest = getTestThirdPartyIDRequest() else {
      if Settings.shared.isAdvertiserTrackingEnabled {
        ConsoleReportBugWithFormattedMessage("Could not make request for custom audience third party id")
      } else {
        ConsoleSucceedWithFormattedMessage(
          "As expected, we cannot create a custom audience third party id request when ATT is not opt in"
        )
      }
      return
    }
    thirdPartyIDRequest.start { _, result, error in
      if let error = error {
        ConsoleReportBugWithFormattedMessage(
          "Received error in sending custom audience third party id request: \(String(describing: error))"
        )
      } else {
        if let resultDict = result as? [String: Any] {
          ConsoleSucceedWithFormattedMessage(
            "Custom audience third party id request response received: \(resultDict)"
          )
        } else {
          ConsoleReportBugWithFormattedMessage(
            "Expected custom audience third party id request response result to be of type Dictionary but got \(type(of: result))"
          )
        }
      }
    }
  }

  @objc func testCheckCodelessIndexingSession() {
    guard let codelessIndexingRequest = getTestCheckCodelessIndexingSessionRequest() else {
      if Settings.shared.isAdvertiserTrackingEnabled {
        ConsoleReportBugWithFormattedMessage("Unexpected: Could not make request for checking the codeless indexing session")
      } else {
        ConsoleSucceedWithFormattedMessage(
          "We cannot check the codeless indexing session when ATT is not opt in"
        )
      }
      return
    }
    codelessIndexingRequest.start { _, result, error in
      if let error = error {
        ConsoleReportBugWithFormattedMessage(
          "Received error in sending codeless indexing session request: \(String(describing: error))"
        )
      } else {
        if let resultDict = result as? [String: Any] {
          ConsoleSucceedWithFormattedMessage(
            "Codeless indexing session request received: \(resultDict)"
          )
        } else {
          ConsoleReportBugWithFormattedMessage(
            "Expected codeless indexing session request response result to be of type Dictionary but got \(type(of: result))"
          )
        }
      }
    }
  }

  @objc func reset() {
    // Drop previously stored events
    PrivacyTestUtils.setIsIOS14(true)
    PrivacyTestUtils.setAdvertiserTrackingStatus(2)
    AppEvents.shared.flush()

    // Reset flags
    PrivacyTestUtils.setFlag("_eventCollectionEnabled", value: false)
    PrivacyTestUtils.setFlag("_advertiserIDCollectionEnabled", value: false)
    PrivacyTestUtils.setAdvertiserTrackingStatus(2)
    PrivacyTestUtils.setDefaultAdvertiserTrackingStatus(2)
    PrivacyTestUtils.setIsIOS14(false)
    PrivacyTestUtils.setIsLATEnabled(false)

    // Reset toggles
    osVersionToggle.setOn(false, animated: true)
    eventCollectionToggle.setOn(false, animated: true)
    advertiserIDCollectionToggle.setOn(false, animated: true)
    LATToggle.setOn(false, animated: true)
    defaultStatusSC.selectedSegmentIndex = 2
    statusSC.selectedSegmentIndex = 2
    consoleView.text = ""
  }

  @objc func publishInstall() {
    PrivacyTestUtils.publishInstall()
  }

  @objc func requestToTrack() {
    if #available(iOS 14.0, *) {
      ATTrackingManager.requestTrackingAuthorization(completionHandler: { status in
        DispatchQueue.main.async {
          ConsoleSucceedWithFormattedMessage(
            "PrivacyToggleViewController Request to track, ATT status: \(status)"
          )
        }
      })
    }
  }

  @objc func selectAdvertisingTrackingStatus(sender: UISegmentedControl) {
    PrivacyTestUtils.setAdvertiserTrackingStatus(UInt(sender.selectedSegmentIndex))
  }

  @objc func selectDefaultAdvertisingTrackingStatus(sender: UISegmentedControl) {
    PrivacyTestUtils.setDefaultAdvertiserTrackingStatus(UInt(sender.selectedSegmentIndex))
  }
}
