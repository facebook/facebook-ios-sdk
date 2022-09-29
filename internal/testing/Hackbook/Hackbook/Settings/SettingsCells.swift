// (c) Meta Platforms, Inc. and affiliates. Confidential and proprietary.

import UIKit

class SettingsTextFieldCell: UITableViewCell, UITextFieldDelegate {
  @IBOutlet var label: UILabel!
  @IBOutlet var textField: UITextField!
  private var inputCompletion: ((String) -> Void)?

  func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
    let currentText = (textField.text ?? "") as NSString
    let newText = currentText.replacingCharacters(in: range, with: string)
    inputCompletion?(newText)
    return true
  }

  func setup(with setting: StringSetting) {
    label.text = setting.name
    textField.text = setting.currentValue ?? ""
    inputCompletion = setting.updateValue
  }
}

class SettingsToggleCell: UITableViewCell {
  @IBOutlet var name: UILabel!
  @IBOutlet var toggle: UISwitch!
  private var toggleCompletion: ((Bool) -> Void)?

  @objc private func valueChanged(_ sender: UISwitch) {
    toggleCompletion?(sender.isOn)
  }

  func setup(with setting: BooleanSetting) {
    name.text = setting.name
    toggle.isOn = setting.isOn
    toggleCompletion = setting.updateValue
    toggle.addTarget(self, action: #selector(valueChanged(_:)), for: .valueChanged)
  }
}
