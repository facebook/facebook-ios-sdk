// (c) Meta Platforms, Inc. and affiliates. Confidential and proprietary.

import UIKit

import FBSDKCoreKit

class PrivacyToggleViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

  #if targetEnvironment(simulator)
  private let toggles: Array = ["iOS 14", "Event Collection Enabled", "IDFA Collection Enabled", "LAT Enabled", "Default ATE", "Set ATE", "Log Event", "Reset", "Publish Install"]
  #else
  private let toggles: Array = ["Event Collection Enabled", "IDFA Collection Enabled", "Default ATE", "Set ATE", "Log Event", "Reset", "Publish Install"]
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

  @objc func selectAdvertisingTrackingStatus(sender: UISegmentedControl) {
    PrivacyTestUtils.setAdvertiserTrackingStatus(UInt(sender.selectedSegmentIndex))
  }

  @objc func selectDefaultAdvertisingTrackingStatus(sender: UISegmentedControl) {
    PrivacyTestUtils.setDefaultAdvertiserTrackingStatus(UInt(sender.selectedSegmentIndex))
  }
}
