// (c) Meta Platforms, Inc. and affiliates. Confidential and proprietary.

import FBSDKCoreKit
import UIKit

@objc
class AppSelectorPicker: UIPickerView, UIPickerViewDataSource, UIPickerViewDelegate {
  let currentSelectedApp = "current_selected_app"
  var appData = NSDictionary(contentsOfFile: Bundle.main.path(forResource: "Apps", ofType: "plist") ?? "")
  @objc var table: UITableView?
  override init(frame: CGRect) {
    super.init(frame: frame)
    self.delegate = self
    self.dataSource = self
  }
  required init?(coder: NSCoder) {
    super.init(coder: coder)
  }
  func updateApp(withName appName: String) {
    guard let appData = appData, let newAppData = appData[appName] as? [String: String ]else {
      return
    }
    Settings.shared.appID = newAppData["App_ID"]
    Settings.shared.clientToken = newAppData["Token"]
    UserDefaults.standard.setValue(appName, forKey: currentSelectedApp)
    table?.reloadData()
    showSuccessAlert()
  }
  func showSuccessAlert() {
    let alert = UIAlertController(title: "", message: "You've selected a new app ID, please logout and/or login for this change to take effect.", preferredStyle: .alert)
    table?.window?.rootViewController?.present(alert, animated: true)
    Timer.scheduledTimer(withTimeInterval: 3, repeats: false) { _ in
        alert.dismiss(animated: true)
    }
  }
  // MARK: UIPickerViewDataSource
  func numberOfComponents(in pickerView: UIPickerView) -> Int {
    return 1
  }
  func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
    guard let appData = appData else {
      return 0
    }
    return appData.allKeys.count
  }
  // MARK: UIPickerViewDelegate
  func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
    guard let appData = appData else {
      return ""
    }
    return appData.allKeys[row] as? String
  }
  func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
    guard let appName = appData?.allKeys[row] as? String else {
      return
    }
    updateApp(withName: appName)
    pickerView.isHidden = true
  }
}
