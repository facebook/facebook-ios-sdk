// (c) Meta Platforms, Inc. and affiliates. Confidential and proprietary.

import Foundation
import FBSDKGamingServicesKit
import UIKit

enum ContextAPICell: Int, CaseIterable {
  case createContext = 0
  case switchContext
  case contextChoose
  case customUpdate

  var text: String {
    switch self {
    case .createContext:
      return "Create Context"
    case .switchContext:
      return "Switch Context"
    case .contextChoose:
      return "Context Choose"
    case .customUpdate:
      return "Perform Custom Update"
    }
  }
}

class ContextAPITableViewController:
  UITableViewController,
  UITextFieldDelegate,
  ContextDialogDelegate
{

  var playerIDTextField: UITextField?
  var contextIDTextField: UITextField?
  let presenter = ContextDialogPresenter()

  override func viewDidLoad() {

  }


  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return ContextAPICell.allCases.count
  }

  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let tableViewCell = UITableViewCell()
    let contextAPICell = ContextAPICell(rawValue: indexPath.row)
    tableViewCell.textLabel?.text = contextAPICell?.text
    tableViewCell.textLabel?.font = UIFont.systemFont(ofSize: 17, weight: .semibold)

    switch indexPath.row {
    case 0:
      let frame = CGRect(x: tableViewCell.frame.maxX/2, y: 0, width: tableViewCell.frame.maxX/2, height: tableViewCell.frame.height)
      let cellTextField = createCellTextField(withFrame: frame, placeholderText:"Enter Player ID")
      self.playerIDTextField = cellTextField
      tableViewCell.contentView.addSubview(cellTextField)
    case 1:
      let frame = CGRect(x: tableViewCell.frame.maxX/2, y: 0, width: tableViewCell.frame.maxX/2, height: tableViewCell.frame.height)
      let cellTextField = createCellTextField(withFrame: frame, placeholderText:"Enter Context ID")
      self.contextIDTextField = cellTextField
      tableViewCell.contentView.addSubview(cellTextField)
    case 2:
      if let cell = tableView.dequeueReusableCell(withIdentifier: "ContextChooseCell") as? ContextChooseCell {
        cell.delegate = self
        return cell
      }
    case 3:
      return tableViewCell
    default:
      tableViewCell.accessoryType = .disclosureIndicator
    }
    return tableViewCell
  }

  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    let cell = ContextAPICell(rawValue: indexPath.row)
    switch cell {
    case .createContext:
      createContext()
    case .switchContext:
      switchContext()
    case .contextChoose:
      break
    case .customUpdate:
      segueToCustomUpdateController()
    case .none:
      return
    }
  }

  func createContext() {
    guard let playerID = self.playerIDTextField?.text, !playerID.isEmpty else {
      return Console.sharedInstance().addMessage(
        "A player ID is missing or is invalid, please fix",
        notificationName:"ConsoleDidReportBugNotification"
      )
    }

    self.playerIDTextField?.resignFirstResponder()
    let content = CreateContextContent(playerID: playerID)
    do {
      try presenter.makeAndShowCreateContextDialog(
        content: content,
        delegate: self
      )
    } catch {
      Console.sharedInstance().addMessage(
        "An error occured presenting the create context dialog: \(error)",
        notificationName:"ConsoleDidReportBugNotification"
      )
    }
  }

  func switchContext() {
    guard let contextID = self.contextIDTextField?.text, !contextID.isEmpty else {
      return Console.sharedInstance().addMessage(
        "A context ID is missing or is invalid, please fix",
        notificationName:"ConsoleDidReportBugNotification"
      )
    }

    self.contextIDTextField?.resignFirstResponder()
    let content = SwitchContextContent.init(contextID: contextID)
    do {
      try presenter.makeAndShowSwitchContextDialog(
        content: content,
        delegate: self
      )
    } catch {
      Console.sharedInstance().addMessage(
        "An error occured presenting the switch context dialog: \(error)",
        notificationName:"ConsoleDidReportBugNotification"
      )
    }
  }

  func segueToCustomUpdateController() {
    self.performSegue(withIdentifier: "customUpdateSegue", sender: self)
  }

  func createCellTextField(withFrame frame: CGRect, placeholderText:String) -> UITextField {
    let cellTextField = UITextField(frame: frame)
    cellTextField.placeholder = placeholderText
    cellTextField.font = UIFont.systemFont(ofSize: 15)
    cellTextField.delegate = self
    return cellTextField
  }


  func contextDialogDidComplete(_ contextDialog: ContextWebDialog) {
    Console.sharedInstance().addMessage(
      "Current context updated with context id: \(GamingContext.current?.identifier ?? "") size: \(GamingContext.current?.size ?? 0)",
      notificationName:"ConsoleDidReportBugNotification"
    )
  }

  func contextDialog(_ contextDialog: ContextWebDialog, didFailWithError error: Error) {
    Console.sharedInstance().addMessage(
      "Context dialog returned with: \(error)",
      notificationName:"ConsoleDidReportBugNotification"
    )
  }

  func contextDialogDidCancel(_ contextDialog: ContextWebDialog) {
    Console.sharedInstance().addMessage(
      "Dialog cancelled",
      notificationName:"ConsoleDidReportBugNotification"
    )
  }

  func textFieldShouldReturn(_ textField: UITextField) -> Bool {
    textField.resignFirstResponder()
    return true;
  }
}

class ContextChooseCell: UITableViewCell, UITextFieldDelegate, UIPickerViewDelegate, UIPickerViewDataSource {

  @IBOutlet var filterTextField: UITextField?
  @IBOutlet var minSizeTextField: UITextField?
  @IBOutlet var maxSizeTextField: UITextField?

  let presenter = ContextDialogPresenter()
  let filterPickerValues = ChooseContextFilter.allCases
  let filterPicker = UIPickerView()
  var delegate: ContextDialogDelegate?

  var selectedFilter: ChooseContextFilter?

  override func awakeFromNib() {
    super.awakeFromNib()
    filterPicker.dataSource = self
    filterPicker.delegate = self
    filterTextField?.delegate = self
    minSizeTextField?.delegate = self
    maxSizeTextField?.delegate = self
    filterTextField?.inputView = filterPicker
  }

  func numberOfComponents(in pickerView: UIPickerView) -> Int {
    return 1
  }

  func pickerView(_ : UIPickerView, numberOfRowsInComponent component: Int) -> Int {
    return filterPickerValues.count
  }

  func pickerView(_: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
    return filterPickerValues[row].name
  }

  func pickerView(_: UIPickerView , didSelectRow row: Int, inComponent component: Int) {
    filterTextField?.text = filterPickerValues[row].name
    self.selectedFilter = filterPickerValues[row]
    filterTextField?.resignFirstResponder()
  }

  @IBAction func showContextChooseDialog() {
    let content = ChooseContextContent()
    if let filter = selectedFilter {
      content.filter = filter
    }
    if let minSize = Int(minSizeTextField?.text ?? "") {
      content.minParticipants = minSize
    }
    if let maxSize = Int(maxSizeTextField?.text ?? "") {
      content.maxParticipants = maxSize
    }
    guard let delegate = delegate else {
      return
    }
    presenter.makeAndShowChooseContextDialog(content: content, delegate: delegate)
  }

  func textFieldShouldReturn(_ textField: UITextField) -> Bool {
    textField.resignFirstResponder()
    return true;
  }

  func textFieldDidBeginEditing(_ textField: UITextField) {
    if textField == self.filterTextField {
      self.filterPicker.isHidden = false
    }
  }
}
