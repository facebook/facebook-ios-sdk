// (c) Meta Platforms, Inc. and affiliates. Confidential and proprietary.

import UIKit

import FBSDKCoreKit

class SKANViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

  private let toggles: Array = [
    "Event Name",
    "Currency",
    "Value",
    "Record Event",
    "New Install"
  ]

  private let consoleView: UITextView = UITextView()
  private let eventTextView: UITextView = UITextView()
  private let currencyTextView: UITextView = UITextView()
  private let valueTextView: UITextView = UITextView()

  private let recordEventButton: UIButton = UIButton()
  private let resetButton: UIButton = UIButton()

  private let tableView: UITableView = UITableView()

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "SKAN"

    consoleView.layer.borderColor = UIColor.lightGray.cgColor
    consoleView.layer.borderWidth = 1
    consoleView.layer.cornerRadius = 3
    consoleView.isEditable = false
    consoleView.accessibilityIdentifier = "textview_console"
    consoleView.frame = CGRect(x: 0, y: 44, width: self.view.frame.width, height: 300)

    eventTextView.frame = CGRect(x: self.view.frame.width / 2, y: 3, width: self.view.frame.width / 2, height: 34)
    eventTextView.layer.borderWidth = 1
    eventTextView.layer.borderColor = UIColor.systemBlue.cgColor
    eventTextView.text = "fb_mobile_purchase"
    eventTextView.accessibilityIdentifier = "testview_event"

    currencyTextView.frame = CGRect(x: self.view.frame.width / 2, y: 3, width: self.view.frame.width / 2, height: 34)
    currencyTextView.layer.borderWidth = 1
    currencyTextView.layer.borderColor = UIColor.systemBlue.cgColor
    currencyTextView.text = "USD"
    currencyTextView.accessibilityIdentifier = "testview_currency"

    valueTextView.frame = CGRect(x: self.view.frame.width / 2, y: 3, width: self.view.frame.width / 2, height: 34)
    valueTextView.layer.borderWidth = 1
    valueTextView.layer.borderColor = UIColor.systemBlue.cgColor
    valueTextView.text = "3"
    valueTextView.accessibilityIdentifier = "testview_value"

    recordEventButton.frame = CGRect(x: 20, y: 3, width: self.view.frame.width - 40, height: 34)
    recordEventButton.backgroundColor = .systemBlue
    recordEventButton.setTitle("Record Event", for: .normal)
    recordEventButton.layer.cornerRadius = 5.0
    recordEventButton.addTarget(self, action: #selector(AEMViewController.recordEvent), for: .touchUpInside)
    recordEventButton.accessibilityIdentifier = "button_record_event"

    resetButton.frame = CGRect(x: 20, y: 3, width: self.view.frame.width - 40, height: 34)
    resetButton.backgroundColor = .systemBlue
    resetButton.setTitle("New Install", for: .normal)
    resetButton.layer.cornerRadius = 5.0
    resetButton.addTarget(self, action: #selector(AEMViewController.reset), for: .touchUpInside)
    resetButton.accessibilityIdentifier = "button_reset"

    tableView.rowHeight = 40
    tableView.register(UITableViewCell.self, forCellReuseIdentifier: "ToggleCell")
    tableView.delegate = self
    tableView.dataSource = self
    tableView.frame = CGRect(x: 0, y: 344, width: self.view.frame.width, height: self.view.frame.height - 344)

    SKANTestUtils.reset(consoleView)
    self.swizzleReporter()

    self.view.addSubview(consoleView)
    self.view.addSubview(tableView)
  }

  // MARK: View Management

  func numberOfSections(in tableView: UITableView) -> Int {
    1
  }

  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    toggles.count
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell { // swiftlint:disable:this  line_length
    let cell = tableView.dequeueReusableCell(withIdentifier: "ToggleCell", for: indexPath)
    cell.selectionStyle = .none

    switch indexPath.row {
    case 0:
      cell.accessoryType = .disclosureIndicator
      cell.textLabel?.text = toggles[indexPath.row]
      cell.accessoryView = eventTextView
      cell.accessibilityIdentifier = "cell_event"
    case 1:
      cell.accessoryType = .disclosureIndicator
      cell.textLabel?.text = toggles[indexPath.row]
      cell.accessoryView = currencyTextView
      cell.accessibilityIdentifier = "cell_currency"
    case 2:
      cell.accessoryType = .disclosureIndicator
      cell.textLabel?.text = toggles[indexPath.row]
      cell.accessoryView = valueTextView
      cell.accessibilityIdentifier = "cell_value"
    case 3:
      cell.layoutMargins = .zero
      cell.accessoryType = .none
      cell.accessoryView = recordEventButton
    case 4:
      cell.layoutMargins = .zero
      cell.accessoryType = .none
      cell.accessoryView = resetButton
    default:
      cell.accessoryType = .disclosureIndicator
      cell.textLabel?.text = toggles[indexPath.row]
      cell.accessoryView = UISwitch()
    }
    return cell
  }

  @objc func reset() {
    SKANTestUtils.reset(consoleView)
  }

  @objc func recordEvent() {
    SKANTestUtils.recordAndUpdateEvent(eventTextView.text,
                                       currency: currencyTextView.text,
                                       value: valueTextView.text,
                                       console: consoleView)
  }

  @objc func swizzleReporter() {
    SKANTestUtils.swizzleReporter(forConsole: consoleView)
  }
}
