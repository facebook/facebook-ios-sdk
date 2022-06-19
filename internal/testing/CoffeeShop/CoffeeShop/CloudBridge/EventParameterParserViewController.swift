// (c) Meta Platforms, Inc. and affiliates. Confidential and proprietary.

import UIKit

class EventParameterParserViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

  weak var delegate: JsonParserDelegate?

  private let toggles: Array = ["Validate", "Set Data"]

  private let textView: UITextView = UITextView()

  private let validationButton: UIButton = UIButton()
  private let generationButton: UIButton = UIButton()

  private let tableView: UITableView = UITableView()

  override func viewDidLoad() {
    super.viewDidLoad()

    textView.layer.borderColor = UIColor.lightGray.cgColor
    textView.layer.borderWidth = 1
    textView.layer.cornerRadius = 3
    textView.isEditable = true
    textView.accessibilityIdentifier = "textview_console"
    textView.frame = CGRect(x: 0, y: 44, width: self.view.frame.width, height: 300)

    validationButton.frame = CGRect(x: 20, y: 3, width: self.view.frame.width - 40, height: 34)
    validationButton.backgroundColor = .systemBlue
    validationButton.setTitle("Validate Parameter", for: .normal)
    validationButton.layer.cornerRadius = 5.0
    validationButton.addTarget(
      self,
      action: #selector(EventParameterParserViewController.validateParameter),
      for: .touchUpInside
    )
    validationButton.accessibilityIdentifier = "button_validate_parameter"

    generationButton.frame = CGRect(x: 20, y: 3, width: self.view.frame.width - 40, height: 34)
    generationButton.backgroundColor = .systemBlue
    generationButton.setTitle("Generate Parameter", for: .normal)
    generationButton.layer.cornerRadius = 5.0
    generationButton.addTarget(
      self,
      action: #selector(EventParameterParserViewController.generateParameter),
      for: .touchUpInside
    )
    generationButton.accessibilityIdentifier = "button_generate_parameter"

    tableView.rowHeight = 40
    tableView.register(UITableViewCell.self, forCellReuseIdentifier: "ParameterCell")
    tableView.delegate = self
    tableView.dataSource = self
    tableView.frame = CGRect(x: 0, y: 344, width: self.view.frame.width, height: self.view.frame.height - 344)

    self.view.addSubview(textView)
    self.view.addSubview(tableView)
  }
  // MARK: View Management

  func numberOfSections(in tableView: UITableView) -> Int {
    1
  }

  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    toggles.count
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell { // swiftlint:disable:this function_body_length line_length
    let cell = tableView.dequeueReusableCell(withIdentifier: "ParameterCell", for: indexPath)
    cell.selectionStyle = .none

    switch indexPath.row {
    case 0:
      cell.layoutMargins = .zero
      cell.accessoryType = .none
      cell.accessoryView = validationButton
    case 1:
      cell.layoutMargins = .zero
      cell.accessoryType = .none
      cell.accessoryView = generationButton
    default:
      cell.accessoryType = .disclosureIndicator
      cell.textLabel?.text = toggles[indexPath.row]
      cell.accessoryView = UISwitch()
    }
    return cell
  }

  @objc func validateParameter() {
    let text = self.textView.text ?? ""
    let jsonData = text.data(using: String.Encoding.utf8)!
    let json = try? JSONSerialization.jsonObject(with: jsonData, options: .mutableContainers)
    if json != nil {
      self.present(validationMessage: "Valid Json")
    } else {
      self.present(validationMessage: "Invalid Json")
    }
  }

  @objc func generateParameter() {
    self.delegate?.setJsonData(self.textView.text)

    self.navigationController?.popViewController(animated: true)
  }

  func present(validationMessage: String) {
    let alert = UIAlertController(
      title: "Validation Result",
      message: validationMessage,
      preferredStyle: .alert
    )
    alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
    self.present(alert, animated: true)
  }
}
