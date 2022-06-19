// (c) Meta Platforms, Inc. and affiliates. Confidential and proprietary.

import UIKit

import FBSDKCoreKit

class CloudBridgeViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, JsonParserDelegate {

  private let toggles: Array = ["Event Name", "Currency", "Value", "Event Parameter", "Endpoint", "Dataset Id", "Access Key", "Parameter Parser", "Log Event"]

  private let consoleView: UITextView = UITextView()
  private let eventTextView: UITextView = UITextView()
  private let currencyTextView: UITextView = UITextView()
  private let valueTextView: UITextView = UITextView()
  private let parameterTextView: UITextView = UITextView()
  private let endpointTextView: UITextView = UITextView()
  private let datasetTextView: UITextView = UITextView()
  private let accessKeyTextView: UITextView = UITextView()

  private let recordEventButton: UIButton = UIButton()
  private let parameterGenerationButton: UIButton = UIButton()

  private let tableView: UITableView = UITableView()

  private var datasetId: String = "885075468745573"
  private var url: String = "https://mar29-appsdk.iots.us"
  private var accessKey: String = "ndREzKMtQP"

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "CloudBridge"

    consoleView.layer.borderColor = UIColor.lightGray.cgColor
    consoleView.layer.borderWidth = 1
    consoleView.layer.cornerRadius = 3
    consoleView.isEditable = false
    consoleView.accessibilityIdentifier = "textview_console"
    consoleView.frame = CGRect(x: 0, y: 44, width: self.view.frame.width, height: 400)

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

    parameterTextView.frame = CGRect(x: self.view.frame.width / 2, y: 3, width: self.view.frame.width / 2, height: 34)
    parameterTextView.layer.borderWidth = 1
    parameterTextView.layer.borderColor = UIColor.systemBlue.cgColor
    parameterTextView.accessibilityIdentifier = "testview_parameter"

    endpointTextView.frame = CGRect(x: self.view.frame.width / 2, y: 3, width: self.view.frame.width / 2, height: 34)
    endpointTextView.layer.borderWidth = 1
    endpointTextView.layer.borderColor = UIColor.systemBlue.cgColor
    endpointTextView.accessibilityIdentifier = "endpoint_value"
    endpointTextView.delegate = self
    endpointTextView.text = url

    datasetTextView.frame = CGRect(x: self.view.frame.width / 2, y: 3, width: self.view.frame.width / 2, height: 34)
    datasetTextView.layer.borderWidth = 1
    datasetTextView.layer.borderColor = UIColor.systemBlue.cgColor
    datasetTextView.accessibilityIdentifier = "dataset_value"
    datasetTextView.delegate = self
    datasetTextView.text = datasetId

    accessKeyTextView.frame = CGRect(x: self.view.frame.width / 2, y: 3, width: self.view.frame.width / 2, height: 34)
    accessKeyTextView.layer.borderWidth = 1
    accessKeyTextView.layer.borderColor = UIColor.systemBlue.cgColor
    accessKeyTextView.accessibilityIdentifier = "accessKey_value"
    accessKeyTextView.delegate = self
    accessKeyTextView.text = accessKey

    parameterGenerationButton.frame = CGRect(x: 20, y: 3, width: self.view.frame.width - 40, height: 34)
    parameterGenerationButton.backgroundColor = .systemBlue
    parameterGenerationButton.setTitle("Parameter Parser", for: .normal)
    parameterGenerationButton.layer.cornerRadius = 5.0
    parameterGenerationButton.addTarget(
      self,
      action: #selector(CloudBridgeViewController.generateParameter),
      for: .touchUpInside
    )
    parameterGenerationButton.accessibilityIdentifier = "button_generate_parameter"

    recordEventButton.frame = CGRect(x: 20, y: 3, width: self.view.frame.width - 40, height: 34)
    recordEventButton.backgroundColor = .systemBlue
    recordEventButton.setTitle("Log Event", for: .normal)
    recordEventButton.layer.cornerRadius = 5.0
    recordEventButton.addTarget(self, action: #selector(CloudBridgeViewController.recordEvent), for: .touchUpInside)
    recordEventButton.accessibilityIdentifier = "button_record_event"

    tableView.rowHeight = 40
    tableView.register(UITableViewCell.self, forCellReuseIdentifier: "ToggleCell")
    tableView.delegate = self
    tableView.dataSource = self
    tableView.frame = CGRect(x: 0, y: 444, width: self.view.frame.width, height: self.view.frame.height - 444)

    self.view.addSubview(consoleView)
    self.view.addSubview(tableView)
    self.reset()
    CloudBridgeTestUtils.setup()
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
      cell.accessoryType = .disclosureIndicator
      cell.textLabel?.text = toggles[indexPath.row]
      cell.accessoryView = parameterTextView
      cell.accessibilityIdentifier = "cell_parameter"
    case 4:
      cell.accessoryType = .disclosureIndicator
      cell.textLabel?.text = toggles[indexPath.row]
      cell.accessoryView = endpointTextView
      cell.accessibilityIdentifier = "cell_endpoint"
    case 5:
      cell.accessoryType = .disclosureIndicator
      cell.textLabel?.text = toggles[indexPath.row]
      cell.accessoryView = datasetTextView
      cell.accessibilityIdentifier = "cell_dataset"
    case 6:
      cell.accessoryType = .disclosureIndicator
      cell.textLabel?.text = toggles[indexPath.row]
      cell.accessoryView = accessKeyTextView
      cell.accessibilityIdentifier = "cell_accesskey"
    case 7:
      cell.layoutMargins = .zero
      cell.accessoryType = .none
      cell.accessoryView = parameterGenerationButton
    case 8:
      cell.layoutMargins = .zero
      cell.accessoryType = .none
      cell.accessoryView = recordEventButton
    default:
      cell.accessoryType = .disclosureIndicator
      cell.textLabel?.text = toggles[indexPath.row]
      cell.accessoryView = UISwitch()
    }
    return cell
  }

  @objc func reset() {
    consoleView.text = ""
  }

  @objc func recordEvent() {
    FBSDKTransformerGraphRequestFactory.shared.configure(datasetID: datasetId, url: url, accessKey: accessKey)

    guard let credentials = FBSDKTransformerGraphRequestFactory.shared.credentials else { return }

    let endpointValues = "\(credentials.capiGatewayURL), dataset: \(credentials.datasetID), accessKey: \(credentials.accessKey)"

    CloudBridgeTestUtils.recordAndUpdateEvent(
      eventTextView.text,
      endpointValues: endpointValues,
      currency: currencyTextView.text,
      value: valueTextView.text,
      eventParameter: parameterTextView.text,
      console: consoleView
    )
    AppEvents.shared.flush()
  }

  @objc func generateParameter() {
    let viewController = EventParameterParserViewController()
    viewController.delegate = self
    self.navigationController?.pushViewController(viewController, animated: true)
  }

  // MARK: Json Management

  func setJsonData(_ data: String?) {
    self.parameterTextView.text = data ?? ""
  }
}

extension CloudBridgeViewController: UITextViewDelegate {
  func textViewDidChange(_ textView: UITextView) {
    if textView == endpointTextView {
      url = textView.text
    }
    else if textView == datasetTextView {
      datasetId = textView.text
    }
    else if textView == accessKeyTextView {
      accessKey = textView.text
    }
  }
}
