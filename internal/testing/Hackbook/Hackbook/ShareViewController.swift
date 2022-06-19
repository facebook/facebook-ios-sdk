// (c) Meta Platforms, Inc. and affiliates. Confidential and proprietary.

import UIKit

class ShareViewController: UITableViewController {

  override func viewDidLoad() {
    super.viewDidLoad()

    title = "Share"

    tableView.register(UITableViewCell.self, forCellReuseIdentifier: "ShareCell")
    tableView.rowHeight = 44
  }

  // MARK: - Table view data source
  override func numberOfSections(in tableView: UITableView) -> Int {
    2
  }

  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    0 == section ? 4 : 1
  }

  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "ShareCell", for: indexPath)
    cell.selectionStyle = .none
    cell.accessoryType = .disclosureIndicator

    let options = [["Share Extension", "Share Dialog", "Share to Stories", "Share to Reels"], ["Message Dialog"]]
    cell.textLabel?.text = options[indexPath.section][indexPath.row]

    return cell
  }

  override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
    0 == section ? "Facebook" : "Messenger"
  }

  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    var vc: UIViewController!

    let storyboard = UIStoryboard(name: "Hackbook", bundle: nil)
    switch indexPath.section {
    case 0:
      switch indexPath.row {
      case 0:
        vc = ActivityViewTableViewController()
      case 1:
        vc = storyboard.instantiateViewController(withIdentifier: "NativeShareDialog")
      case 2:
        vc = storyboard.instantiateViewController(withIdentifier: "ShareToStories")
      case 3:
        vc = ShareToReelsViewController()
      default:
        break
      }

    case 1:
      vc = storyboard.instantiateViewController(withIdentifier: "MessageShareDialog")
    default:
      break
    }
    if vc != nil {
      navigationController?.pushViewController(vc, animated: true)
    }
  }
}
