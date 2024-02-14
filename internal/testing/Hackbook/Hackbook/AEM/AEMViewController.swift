// (c) Meta Platforms, Inc. and affiliates. Confidential and proprietary.

import UIKit

import AppTrackingTransparency
import FBSDKCoreKit

class AEMViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, JsonParserDelegate {

  private let toggles: Array = [
    "Campaign ID",
    "Business ID",
    "Event Name",
    "Currency",
    "Value",
    "Event Parameter",
    "Record Event",
    "Publish Install",
    "New Ads Click",
    "Generate Parameter",
    "Request To Track",
    "ATE",
    "Deeplink Type",
  ]

  private let consoleView: UITextView = .init()
  private let campaignTextView: UITextView = .init()
  private let businessIDTextView: UITextView = .init()
  private let eventTextView: UITextView = .init()
  private let currencyTextView: UITextView = .init()
  private let valueTextView: UITextView = .init()
  private let parameterTextView: UITextView = .init()

  private let recordEventButton: UIButton = .init()
  private let publishInstallButton: UIButton = .init()
  private let resetButton: UIButton = .init()
  private let parameterGenerationButton: UIButton = .init()
  private let requestToTrackButton: UIButton = .init()
  private let ATEToggle: UISwitch = .init()
  private let deeplinkTypeSegmentedControl: UISegmentedControl = .init()

  private var deeplinkType: DeeplinkURLType = .customURLScheme

  private let tableView: UITableView = .init()

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "AEM"

    consoleView.layer.borderColor = UIColor.lightGray.cgColor
    consoleView.layer.borderWidth = 1
    consoleView.layer.cornerRadius = 3
    consoleView.isEditable = false
    consoleView.accessibilityIdentifier = "textview_console"
    consoleView.frame = CGRect(x: 0, y: 44, width: view.frame.width, height: 300)

    campaignTextView.frame = CGRect(x: view.frame.width / 2, y: 3, width: view.frame.width / 2, height: 34)
    campaignTextView.layer.borderWidth = 1
    campaignTextView.layer.borderColor = UIColor.systemBlue.cgColor
    campaignTextView.text = "test_campaign_1111"
    campaignTextView.accessibilityIdentifier = "test_campaign"

    businessIDTextView.frame = CGRect(x: view.frame.width / 2, y: 3, width: view.frame.width / 2, height: 34)
    businessIDTextView.layer.borderWidth = 1
    businessIDTextView.layer.borderColor = UIColor.systemBlue.cgColor
    businessIDTextView.text = "Hackbook"
    businessIDTextView.accessibilityIdentifier = "test_business_id"

    eventTextView.frame = CGRect(x: view.frame.width / 2, y: 3, width: view.frame.width / 2, height: 34)
    eventTextView.layer.borderWidth = 1
    eventTextView.layer.borderColor = UIColor.systemBlue.cgColor
    eventTextView.text = "fb_mobile_purchase"
    eventTextView.accessibilityIdentifier = "testview_event"

    currencyTextView.frame = CGRect(x: view.frame.width / 2, y: 3, width: view.frame.width / 2, height: 34)
    currencyTextView.layer.borderWidth = 1
    currencyTextView.layer.borderColor = UIColor.systemBlue.cgColor
    currencyTextView.text = "USD"
    currencyTextView.accessibilityIdentifier = "testview_currency"

    valueTextView.frame = CGRect(x: view.frame.width / 2, y: 3, width: view.frame.width / 2, height: 34)
    valueTextView.layer.borderWidth = 1
    valueTextView.layer.borderColor = UIColor.systemBlue.cgColor
    valueTextView.text = "3"
    valueTextView.accessibilityIdentifier = "testview_value"

    parameterTextView.frame = CGRect(x: view.frame.width / 2, y: 3, width: view.frame.width / 2, height: 34)
    parameterTextView.layer.borderWidth = 1
    parameterTextView.layer.borderColor = UIColor.systemBlue.cgColor
    parameterTextView.accessibilityIdentifier = "testview_parameter"

    deeplinkTypeSegmentedControl.frame = CGRect(x: 20, y: 3, width: view.bounds.width - 40, height: 34)
    deeplinkTypeSegmentedControl.insertSegment(withTitle: "Custom URL Scheme", at: DeeplinkURLType.customURLScheme.rawValue, animated: false)
    deeplinkTypeSegmentedControl.insertSegment(withTitle: "Universal Link", at: DeeplinkURLType.universalLink.rawValue, animated: false)
    deeplinkTypeSegmentedControl.addTarget(self, action: #selector(deeplinkTypeValueChanged(_:)), for: .valueChanged)
    deeplinkTypeSegmentedControl.accessibilityIdentifier = "deeplink_type_segmented_control"
    deeplinkTypeSegmentedControl.selectedSegmentIndex = deeplinkType.rawValue

    recordEventButton.frame = CGRect(x: 20, y: 3, width: view.frame.width - 40, height: 34)
    recordEventButton.backgroundColor = .systemBlue
    recordEventButton.setTitle("Record Event", for: .normal)
    recordEventButton.layer.cornerRadius = 5.0
    recordEventButton.addTarget(self, action: #selector(AEMViewController.recordEvent), for: .touchUpInside)
    recordEventButton.accessibilityIdentifier = "button_record_event"

    publishInstallButton.frame = CGRect(x: 20, y: 3, width: view.frame.width - 40, height: 34)
    publishInstallButton.backgroundColor = .systemBlue
    publishInstallButton.setTitle("Publish Install", for: .normal)
    publishInstallButton.layer.cornerRadius = 5.0
    publishInstallButton.addTarget(self, action: #selector(AEMViewController.publishInstall), for: .touchUpInside)
    publishInstallButton.accessibilityIdentifier = "button_publish_install"

    requestToTrackButton.frame = CGRect(x: 20, y: 3, width: view.frame.width - 40, height: 34)
    requestToTrackButton.backgroundColor = .systemBlue
    requestToTrackButton.setTitle("Request To Track", for: .normal)
    requestToTrackButton.layer.cornerRadius = 5.0
    requestToTrackButton.addTarget(self, action: #selector(AEMViewController.requestToTrack), for: .touchUpInside)
    requestToTrackButton.accessibilityIdentifier = "button_request_to_track"

    resetButton.frame = CGRect(x: 20, y: 3, width: view.frame.width - 40, height: 34)
    resetButton.backgroundColor = .systemBlue
    resetButton.setTitle("New Ads Click", for: .normal)
    resetButton.layer.cornerRadius = 5.0
    resetButton.addTarget(self, action: #selector(AEMViewController.reset), for: .touchUpInside)
    resetButton.accessibilityIdentifier = "button_reset"

    parameterGenerationButton.frame = CGRect(x: 20, y: 3, width: view.frame.width - 40, height: 34)
    parameterGenerationButton.backgroundColor = .systemBlue
    parameterGenerationButton.setTitle("Parameter Parser", for: .normal)
    parameterGenerationButton.layer.cornerRadius = 5.0
    parameterGenerationButton.addTarget(
      self,
      action: #selector(AEMViewController.generateParameter),
      for: .touchUpInside
    )
    parameterGenerationButton.accessibilityIdentifier = "button_generate_parameter"

    ATEToggle.addTarget(self, action: #selector(AEMViewController.switchATE(sender:)), for: .valueChanged)
    ATEToggle.isOn = true
    Settings.shared.isAdvertiserTrackingEnabled = true

    tableView.rowHeight = 40
    tableView.register(UITableViewCell.self, forCellReuseIdentifier: "ToggleCell")
    tableView.delegate = self
    tableView.dataSource = self
    tableView.frame = CGRect(x: 0, y: 344, width: view.frame.width, height: view.frame.height - 344)

    AEMTestUtils.reset(consoleView)
    swizzleReporter()

    navigationController?.navigationBar.backgroundColor = .white
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

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell { // swiftlint:disable:this function_body_length line_length
    let cell = tableView.dequeueReusableCell(withIdentifier: "ToggleCell", for: indexPath)
    cell.selectionStyle = .none

    switch indexPath.row {
    case 0:
      cell.accessoryType = .disclosureIndicator
      cell.textLabel?.text = toggles[indexPath.row]
      cell.accessoryView = campaignTextView
      cell.accessibilityIdentifier = "cell_campaign"
    case 1:
      cell.accessoryType = .disclosureIndicator
      cell.textLabel?.text = toggles[indexPath.row]
      cell.accessoryView = businessIDTextView
      cell.accessibilityIdentifier = "cell_business_id"
    case 2:
      cell.accessoryType = .disclosureIndicator
      cell.textLabel?.text = toggles[indexPath.row]
      cell.accessoryView = eventTextView
      cell.accessibilityIdentifier = "cell_event"
    case 3:
      cell.accessoryType = .disclosureIndicator
      cell.textLabel?.text = toggles[indexPath.row]
      cell.accessoryView = currencyTextView
      cell.accessibilityIdentifier = "cell_currency"
    case 4:
      cell.accessoryType = .disclosureIndicator
      cell.textLabel?.text = toggles[indexPath.row]
      cell.accessoryView = valueTextView
      cell.accessibilityIdentifier = "cell_value"
    case 5:
      cell.accessoryType = .disclosureIndicator
      cell.textLabel?.text = toggles[indexPath.row]
      cell.accessoryView = parameterTextView
      cell.accessibilityIdentifier = "cell_parameter"
    case 6:
      cell.layoutMargins = .zero
      cell.accessoryType = .none
      cell.accessoryView = recordEventButton
    case 7:
      cell.layoutMargins = .zero
      cell.accessoryType = .none
      cell.accessoryView = publishInstallButton
    case 8:
      cell.layoutMargins = .zero
      cell.accessoryType = .none
      cell.accessoryView = resetButton
    case 9:
      cell.layoutMargins = .zero
      cell.accessoryType = .none
      cell.accessoryView = parameterGenerationButton
    case 10:
      cell.layoutMargins = .zero
      cell.accessoryType = .none
      cell.accessoryView = requestToTrackButton
    case 11:
      cell.accessoryType = .disclosureIndicator
      cell.textLabel?.text = toggles[indexPath.row]
      cell.accessoryView = ATEToggle
      cell.accessibilityIdentifier = "cell_ate"
    case 12:
      cell.layoutMargins = .zero
      cell.accessoryType = .none
      cell.accessoryView = deeplinkTypeSegmentedControl
    default:
      cell.accessoryType = .disclosureIndicator
      cell.textLabel?.text = toggles[indexPath.row]
      cell.accessoryView = UISwitch()
    }
    return cell
  }

  // MARK: Json Management

  func setJsonData(_ data: String?) {
    parameterTextView.text = data ?? ""
  }

  @objc func reset() {
    AEMTestUtils.reset(
      consoleView,
      campaign: campaignTextView.text,
      businessID: businessIDTextView.text,
      deeplinkType: deeplinkType
    )
  }

  @objc func recordEvent() {
    AEMTestUtils.recordAndUpdateEvent(
      eventTextView.text,
      currency: currencyTextView.text,
      value: valueTextView.text,
      eventParameter: parameterTextView.text,
      console: consoleView
    )
  }

  @objc func publishInstall() {
    AEMTestUtils.publishInstall(consoleView)
  }

  @objc func requestToTrack() {
    if #available(iOS 14.0, *) {
      ATTrackingManager.requestTrackingAuthorization(completionHandler: { status in
        DispatchQueue.main.async {
          ConsoleSucceedWithFormattedMessage(
            "AEMViewController Request to track, ATT status: \(status)"
          )
        }
      })
    }
  }

  @objc func swizzleReporter() {
    AEMTestUtils.swizzleReporter(forConsole: consoleView)
  }

  @objc func generateParameter() {
    let viewController = AEMEventParameterViewController()
    viewController.delegate = self
    navigationController?.pushViewController(viewController, animated: true)
  }

  @objc func switchATE(sender: UISwitch) {
    Settings.shared.isAdvertiserTrackingEnabled = sender.isOn
  }

  @objc private func deeplinkTypeValueChanged(_ sender: UISegmentedControl) {
    deeplinkType = DeeplinkURLType(rawValue: sender.selectedSegmentIndex)!
  }
}
