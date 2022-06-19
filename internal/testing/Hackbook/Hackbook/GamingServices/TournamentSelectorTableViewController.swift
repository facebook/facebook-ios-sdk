// (c) Meta Platforms, Inc. and affiliates. Confidential and proprietary.

import Foundation
import FBSDKGamingServicesKit

class TournamentSelectorTableViewController: UITableViewController {
  var selectedTournamentCompletion: ((Tournament) -> Void)?
  var tournaments: [Tournament] = []

  init(withTournaments tournaments: [Tournament], selectionCompletion:  @escaping ((Tournament) -> Void)) {
    self.selectedTournamentCompletion = selectionCompletion
    self.tournaments = tournaments

    super.init(style: .plain)
  }

  required init?(coder: NSCoder) {
    super.init(coder: coder)
  }

  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return tournaments.count + 1 // adds one because first row will have "Select tournament text"
  }

  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let tableViewCell = UITableViewCell()
    if indexPath.row == 0 {
      tableViewCell.textLabel?.text = "Select a Tournament"
    } else {
      tableViewCell.textLabel?.text = "\(tournaments[indexPath.row - 1].title ?? "") ID: \(tournaments[indexPath.row - 1].identifier)"
    }
    return tableViewCell
  }

  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    if let selectCompletion = selectedTournamentCompletion, indexPath.row != 0 {
      selectCompletion(tournaments[indexPath.row-1])
    }
  }
}
