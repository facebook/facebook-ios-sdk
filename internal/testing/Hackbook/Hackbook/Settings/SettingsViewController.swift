// (c) Meta Platforms, Inc. and affiliates. Confidential and proprietary.

import FBSDKCoreKit
import UIKit

struct BooleanSetting {
  let name: String
  let isOn: Bool
  let updateValue: (Bool) -> Void
}

struct StringSetting {
  let name: String
  let currentValue: String?
  let updateValue: (String) -> Void
}

class SettingsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

  @IBOutlet private var tableView: UITableView!

  private let ephemeralSettings = [
    StringSetting(
      name: "AppID",
      currentValue: Settings.shared.appID,
      updateValue: { Settings.shared.appID = $0 }
    ),
    StringSetting(
      name: "UrlSchemeSuffix",
      currentValue: Settings.shared.appURLSchemeSuffix,
      updateValue: { Settings.shared.appURLSchemeSuffix = $0 }
    ),
    StringSetting(
      name: "ClientToken",
      currentValue: Settings.shared.clientToken,
      updateValue: { Settings.shared.clientToken = $0 }
    ),
    StringSetting(
      name: "DisplayName",
      currentValue: Settings.shared.displayName,
      updateValue: { Settings.shared.displayName = $0 }
    ),
    StringSetting(
      name: "DomainPart",
      currentValue: Settings.shared.facebookDomainPart,
      updateValue: { Settings.shared.facebookDomainPart = $0 }
    ),
  ]

  private let cacheableSettings: [BooleanSetting] = [
    BooleanSetting(
      name: "AutoLogAppEventsEnabled",
      isOn: Settings.shared.isAutoLogAppEventsEnabled,
      updateValue: { Settings.shared.isAutoLogAppEventsEnabled = $0 }
    ),
    BooleanSetting(
      name: "AdvertiserIDCollectionEnabled",
      isOn: Settings.shared.isAdvertiserIDCollectionEnabled,
      updateValue: { Settings.shared.isAdvertiserIDCollectionEnabled = $0 }
    ),
    BooleanSetting(
      name: "CodelessDebugLogEnabled",
      isOn: Settings.shared.isCodelessDebugLogEnabled,
      updateValue: { Settings.shared.isCodelessDebugLogEnabled = $0 }
    ),
  ]

  // MARK: - TableViewDataSource

  func numberOfSections(in tableView: UITableView) -> Int {
    2
  }

  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    section == 0 ? cacheableSettings.count : ephemeralSettings.count
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    indexPath.section == 0 ? configuredToggleCell(for: indexPath) : configuredTextFieldCell(for: indexPath)
  }

  func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
    section == 0 ? "Cacheable Settings" : "Ephemeral Settings"
  }

  func configuredToggleCell(for indexPath: IndexPath) -> SettingsToggleCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "SettingsToggleCell", for: indexPath)

    guard let toggleCell = cell as? SettingsToggleCell else {
      fatalError("Tableview must register SettingsToggleCell in storyboard or code")
    }

    toggleCell.setup(with: cacheableSettings[indexPath.row])
    return toggleCell
  }

  func configuredTextFieldCell(for indexPath: IndexPath) -> SettingsTextFieldCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "SettingsTextFieldCell", for: indexPath)

    guard let inputCell = cell as? SettingsTextFieldCell else {
      fatalError("Tableview must register SettingsToggleCell in storyboard or code")
    }

    inputCell.setup(with: ephemeralSettings[indexPath.row])
    return inputCell
  }
}
