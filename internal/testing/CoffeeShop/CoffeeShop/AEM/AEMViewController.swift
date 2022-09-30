// (c) Meta Platforms, Inc. and affiliates. Confidential and proprietary.

import UIKit

import FBSDKCoreKit

class AEMViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

  private let toggles: Array = ["Campaign ID", "Event Name", "Currency", "Value", "Record Event", "Record Consecutive Events", "New Ads Click", "Deeplink Type"]

  private let consoleView: UITextView = .init()
  private let campaignTextView: UITextView = .init()
  private let eventTextView: UITextView = .init()
  private let currencyTextView: UITextView = .init()
  private let valueTextView: UITextView = .init()

  private let recordEventButton: UIButton = .init()
  private let recordConsecutiveEventsButton: UIButton = .init()
  private let resetButton: UIButton = .init()
  private let deeplinkTypeSegmentedControl: UISegmentedControl = .init()

  private let tableView: UITableView = .init()

  private var deeplinkType: DeeplinkUrlType = .customUrlScheme

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "AEM"

    consoleView.layer.borderColor = UIColor.lightGray.cgColor
    consoleView.layer.borderWidth = 1
    consoleView.layer.cornerRadius = 3
    consoleView.isEditable = false
    consoleView.accessibilityIdentifier = "textview_console"
    consoleView.frame = CGRect(x: 0, y: 44, width: view.frame.width, height: 400)

    campaignTextView.frame = CGRect(x: view.frame.width / 2, y: 3, width: view.frame.width / 2, height: 34)
    campaignTextView.layer.borderWidth = 1
    campaignTextView.layer.borderColor = UIColor.systemBlue.cgColor
    campaignTextView.text = "test_campaign_1111"
    campaignTextView.accessibilityIdentifier = "test_campaign"

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

    recordEventButton.frame = CGRect(x: 20, y: 3, width: view.frame.width - 40, height: 34)
    recordEventButton.backgroundColor = .systemBlue
    recordEventButton.setTitle("Record Event", for: .normal)
    recordEventButton.layer.cornerRadius = 5.0
    recordEventButton.addTarget(self, action: #selector(AEMViewController.recordEvent), for: .touchUpInside)
    recordEventButton.accessibilityIdentifier = "button_record_event"

    recordConsecutiveEventsButton.frame = CGRect(x: 20, y: 3, width: view.frame.width - 40, height: 34)
    recordConsecutiveEventsButton.backgroundColor = .systemBlue
    recordConsecutiveEventsButton.setTitle("Record Consecutive Events", for: .normal)
    recordConsecutiveEventsButton.layer.cornerRadius = 5.0
    recordConsecutiveEventsButton.addTarget(self, action: #selector(AEMViewController.recordConsecutiveEvents), for: .touchUpInside)
    recordConsecutiveEventsButton.accessibilityIdentifier = "button_record_consecutive_event"

    resetButton.frame = CGRect(x: 20, y: 3, width: view.frame.width - 40, height: 34)
    resetButton.backgroundColor = .systemBlue
    resetButton.setTitle("New Ads Click", for: .normal)
    resetButton.layer.cornerRadius = 5.0
    resetButton.addTarget(self, action: #selector(AEMViewController.reset), for: .touchUpInside)
    resetButton.accessibilityIdentifier = "button_reset"

    deeplinkTypeSegmentedControl.frame = CGRect(x: 20, y: 3, width: view.bounds.width - 40, height: 34)
    deeplinkTypeSegmentedControl.insertSegment(withTitle: "Custom URL Scheme", at: DeeplinkUrlType.customUrlScheme.rawValue, animated: false)
    deeplinkTypeSegmentedControl.insertSegment(withTitle: "Universal Link", at: DeeplinkUrlType.universalLink.rawValue, animated: false)
    deeplinkTypeSegmentedControl.addTarget(self, action: #selector(deeplinkTypeValueChanged(_:)), for: .valueChanged)
    deeplinkTypeSegmentedControl.accessibilityIdentifier = "deeplink_type_segmented_control"
    deeplinkTypeSegmentedControl.selectedSegmentIndex = deeplinkType.rawValue

    tableView.rowHeight = 40
    tableView.register(UITableViewCell.self, forCellReuseIdentifier: "ToggleCell")
    tableView.delegate = self
    tableView.dataSource = self
    tableView.frame = CGRect(x: 0, y: 444, width: view.frame.width, height: view.frame.height - 444)

    AEMTestUtils.reset(consoleView)
    swizzleReporter()

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

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell { // swiftlint:disable:this cyclomatic_complexity function_body_length line_length
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
      cell.accessoryView = eventTextView
      cell.accessibilityIdentifier = "cell_event"
    case 2:
      cell.accessoryType = .disclosureIndicator
      cell.textLabel?.text = toggles[indexPath.row]
      cell.accessoryView = currencyTextView
      cell.accessibilityIdentifier = "cell_currency"
    case 3:
      cell.accessoryType = .disclosureIndicator
      cell.textLabel?.text = toggles[indexPath.row]
      cell.accessoryView = valueTextView
      cell.accessibilityIdentifier = "cell_value"
    case 4:
      cell.layoutMargins = .zero
      cell.accessoryType = .none
      cell.accessoryView = recordEventButton
    case 5:
      cell.layoutMargins = .zero
      cell.accessoryType = .none
      cell.accessoryView = recordConsecutiveEventsButton
    case 6:
      cell.layoutMargins = .zero
      cell.accessoryType = .none
      cell.accessoryView = resetButton
    case 7:
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

  @objc func reset() {
    AEMTestUtils.reset(
      consoleView,
      campaign: campaignTextView.text,
      deeplinkType: deeplinkType
    )
  }

  @objc private func deeplinkTypeValueChanged(_ sender: UISegmentedControl) {
    deeplinkType = DeeplinkUrlType(rawValue: sender.selectedSegmentIndex)!
  }

  @objc func recordEvent() {
    AEMTestUtils.recordAndUpdateEvent(
      eventTextView.text,
      currency: currencyTextView.text,
      value: valueTextView.text,
      console: consoleView
    )
  }

  @objc func recordConsecutiveEvents() {
    for event in eventTextView.text.components(separatedBy: ",") {
      if event.isEmpty {
        continue
      }
      AEMTestUtils.recordAndUpdateEvent(
        event,
        currency: currencyTextView.text,
        value: valueTextView.text,
        console: consoleView
      )
    }
  }

  @objc func swizzleReporter() {
    AEMTestUtils.swizzleReporter(forConsole: consoleView)
  }
}
