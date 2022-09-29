// (c) Meta Platforms, Inc. and affiliates. Confidential and proprietary.

import FBSDKGamingServicesKit
import Foundation

enum TournamentCell: Int, CaseIterable {
  case get = 0
  case post
  case shareUpdate
  case shareCreate

  var text: String {
    switch self {
    case .get:
      return "Get Tournaments"
    case .post:
      return "Post Score to Tournament"
    case .shareUpdate:
      return "Update Tournament and Share"
    case .shareCreate:
      return "Create Tournament and Share"
    }
  }
}

class TournamentsTableViewController: UITableViewController, UITextFieldDelegate, ShareTournamentDialogDelegate {

  var tournamentSelectorTableViewController: TournamentSelectorTableViewController?
  var fetchedTournaments: [Tournament] = []
  var tournamentIDFromFBAPP: String?
  var postScoreTextField: UITextField?
  var updateScoreTextField: UITextField?
  var createScoreTextField: UITextField?
  var payloadObserver: GamingPayloadObserver?

  override func viewDidLoad() {
    payloadObserver = GamingPayloadObserver(delegate: self)
  }

  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return TournamentCell.allCases.count
  }

  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let tableViewCell = UITableViewCell()
    let tournamentCell = TournamentCell(rawValue: indexPath.row)
    tableViewCell.textLabel?.text = tournamentCell?.text

    switch indexPath.row {
    case 1:
      let frame = CGRect(x: tableViewCell.frame.maxX / 1.25, y: 0, width: 100, height: tableViewCell.frame.height)
      let cellTextField = createCellTextField(withFrame: frame, placeholderText: "Enter Score")
      postScoreTextField = cellTextField
      tableViewCell.contentView.addSubview(cellTextField)
    case 2:
      let frame = CGRect(x: tableViewCell.frame.maxX / 1.25, y: 0, width: 100, height: tableViewCell.frame.height)
      let cellTextField = createCellTextField(withFrame: frame, placeholderText: "Enter Score")
      updateScoreTextField = cellTextField
      tableViewCell.contentView.addSubview(cellTextField)
    case 3:
      let frame = CGRect(x: tableViewCell.frame.maxX / 1.25, y: 0, width: 100, height: tableViewCell.frame.height)
      let cellTextField = createCellTextField(withFrame: frame, placeholderText: "Enter Score")
      createScoreTextField = cellTextField
      tableViewCell.contentView.addSubview(cellTextField)
    default:
      tableViewCell.accessoryType = .disclosureIndicator
    }
    return tableViewCell
  }

  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    let cell = TournamentCell(rawValue: indexPath.row)
    switch cell {
    case .get:
      getTournaments()
    case .post:
      if tournamentIDFromFBAPP != nil {
        return useTournamentIDFromFBToPeform(tournamentAPI: .post)
      }
      selectTournament(andPerform: .post)
    case .shareUpdate:
      if tournamentIDFromFBAPP != nil {
        return useTournamentIDFromFBToPeform(tournamentAPI: .shareUpdate)
      }
      selectTournament(andPerform: .shareUpdate)
    case .shareCreate:
      showCreateAndShareTournamentDialog()
    case .none:
      return
    }
  }

  func getTournaments() {
    Console.sharedInstance().addMessage("Attempting to fetch tournaments", notificationName: "ConsoleDidSucceedNotification")
    TournamentFetcher().fetchTournaments { result in
      switch result {
      case let .success(tournaments):
        self.fetchedTournaments = tournaments
        Console.sharedInstance().addMessage("Tournaments did succeed with \(tournaments)", notificationName: "ConsoleDidSucceedNotification")
      case let .failure(error):
        Console.sharedInstance().addMessage("Please report bug: \(error)", notificationName: "ConsoleDidReportBugNotification")
      }
    }
  }

  func useTournamentIDFromFBToPeform(tournamentAPI: TournamentCell) {
    guard let tournamentID = tournamentIDFromFBAPP else {
      return Console.sharedInstance().addMessage(
        "User was not app switched to native app to start tournament use get tournaments",
        notificationName: "ConsoleDidReportBugNotification"
      )
    }

    switch tournamentAPI {
    case .post:
      post(tournamentId: tournamentID)
    case .shareUpdate:
      showShareDialog(tournamentID: tournamentID)
    default:
      break
    }
  }

  func selectTournament(andPerform tournamentAPI: TournamentCell) {
    guard !fetchedTournaments.isEmpty else {
      return Console.sharedInstance().addMessage(
        "Can't find a tournament to update, use Get Tournaments to fetch list of tournaments",
        notificationName: "ConsoleDidReportBugNotification"
      )
    }

    let tournamentSelectorTableViewController = TournamentSelectorTableViewController(withTournaments: fetchedTournaments) { [weak self] selectedTournament in
      guard let strongSelf = self else {
        return
      }

      switch tournamentAPI {
      case .post:
        strongSelf.post(tournament: selectedTournament)
      case .shareUpdate:
        strongSelf.showShareDialog(tournament: selectedTournament)
      default:
        break
      }
      strongSelf.dismiss(animated: true)
    }
    self.tournamentSelectorTableViewController = tournamentSelectorTableViewController
    present(tournamentSelectorTableViewController, animated: true)
  }

  func post(tournament: Tournament) {
    guard let scoreText = postScoreTextField?.text, let score = Int(scoreText) else {
      return Console.sharedInstance().addMessage(
        "A score is missing or is invalid, please fix",
        notificationName: "ConsoleDidReportBugNotification"
      )
    }
    TournamentUpdater().update(tournament: tournament, score: score) { result in
      switch result {
      case .success:
        Console.sharedInstance().addMessage("Tournament score update success!", notificationName: "ConsoleDidSucceedNotification")
      case let .failure(error):
        Console.sharedInstance().addMessage("Please report bug: \(error)", notificationName: "ConsoleDidReportBugNotification")
      }
    }
  }

  func post(tournamentId: String) {
    guard let scoreText = postScoreTextField?.text, let score = Int(scoreText) else {
      return Console.sharedInstance().addMessage(
        "A score is missing or is invalid, please fix",
        notificationName: "ConsoleDidReportBugNotification"
      )
    }

    TournamentUpdater().update(tournamentID: tournamentId, score: score) { result in
      switch result {
      case .success:
        Console.sharedInstance().addMessage("Tournament score update success!", notificationName: "ConsoleDidSucceedNotification")
      case let .failure(error):
        Console.sharedInstance().addMessage("Please report bug: \(error)", notificationName: "ConsoleDidReportBugNotification")
      }
    }
  }

  func createCellTextField(withFrame frame: CGRect, placeholderText: String) -> UITextField {
    let cellTextField = UITextField(frame: frame)
    cellTextField.placeholder = placeholderText
    cellTextField.font = UIFont.systemFont(ofSize: 15)
    cellTextField.delegate = self
    return cellTextField
  }

  func showShareDialog(tournament: Tournament) {
    guard let scoreText = updateScoreTextField?.text, let score = Int(scoreText) else {
      return Console.sharedInstance().addMessage(
        "A score is missing or is invalid, please fix",
        notificationName: "ConsoleDidReportBugNotification"
      )
    }
    let shareDialog = ShareTournamentDialog(delegate: self)
    do {
      try shareDialog.show(score: score, tournament: tournament)
    } catch {
      Console.sharedInstance().addMessage("Please report bug: \(error)", notificationName: "ConsoleDidReportBugNotification")
    }
  }

  func showShareDialog(tournamentID: String) {
    guard let scoreText = updateScoreTextField?.text, let score = Int(scoreText) else {
      return Console.sharedInstance().addMessage(
        "A score is missing or is invalid, please fix",
        notificationName: "ConsoleDidReportBugNotification"
      )
    }

    let shareDialog = ShareTournamentDialog(delegate: self)
    do {
      try shareDialog.show(score: score, tournamentID: tournamentID)
    } catch {
      Console.sharedInstance().addMessage("Please report bug: \(error)", notificationName: "ConsoleDidReportBugNotification")
    }
  }

  func showCreateAndShareTournamentDialog() {
    guard let scoreText = createScoreTextField?.text, let score = Int(scoreText) else {
      return Console.sharedInstance().addMessage("A score is missing or is invalid, please fix", notificationName: "ConsoleDidReportBugNotification")
    }
    let shareDialog = ShareTournamentDialog(delegate: self)
    let twoHoursFromNow = Calendar.current.date(byAdding: .hour, value: 2, to: Date())
    let config = TournamentConfig(title: "iOS Native Tourny", endTime: twoHoursFromNow, payload: "iOS Native Tournament Hackbook")
    do {
      try shareDialog.show(initialScore: score, config: config)
    } catch {
      Console.sharedInstance().addMessage("Please report bug: \(error)", notificationName: "ConsoleDidReportBugNotification")
    }
  }

  func didComplete(dialog: ShareTournamentDialog, tournament: Tournament) {
    Console.sharedInstance().addMessage("Tournament dialog Completed: \(tournament)", notificationName: "ConsoleDidSucceedNotification")
  }

  func didFail(withError error: Error, dialog: ShareTournamentDialog) {
    Console.sharedInstance().addMessage("Please report bug: \(error)", notificationName: "ConsoleDidReportBugNotification")
  }

  func didCancel(dialog: ShareTournamentDialog) {
    Console.sharedInstance().addMessage("Tournament dialog did cancel", notificationName: "ConsoleDidSucceedNotification")
  }

  func textFieldShouldReturn(_ textField: UITextField) -> Bool {
    textField.resignFirstResponder()
    return true
  }
}

extension TournamentsTableViewController: GamingPayloadDelegate {
  func parsedTournamentURLContaining(_ payload: GamingPayload, tournamentID: String) {
    Console.sharedInstance().addMessage("Tournament was parsed \(tournamentID) and you can update or share this tournament", notificationName: "ConsoleDidSucceedNotification")
    tournamentIDFromFBAPP = tournamentID
  }
}
