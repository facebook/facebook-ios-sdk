// (c) Meta Platforms, Inc. and affiliates. Confidential and proprietary.

import UIKit

class SKProductDetailViewController: UIViewController {

  var tableView = UITableView()
  var productID: String?
  var productTitle: String?
  var productDescription: String?
  var price: String?
  private static let cellIdentifier = "SKProductDetailCellID"

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .white
    setupTableView()
  }

  private func setupTableView() {
    tableView.register(UITableViewCell.self, forCellReuseIdentifier: Self.cellIdentifier)
    tableView.dataSource = self
    view.addSubview(tableView)
    tableView.translatesAutoresizingMaskIntoConstraints = false
    tableView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
    tableView.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
    tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
    tableView.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
  }
}

extension SKProductDetailViewController: UITableViewDataSource {
  private func getCellText(section: Int) -> String? {
    switch section {
    case 0: return productID
    case 1: return productTitle
    case 2: return productDescription
    case 3: return price
    default: return ""
    }
  }

  func numberOfSections(in tableView: UITableView) -> Int {
    return 4
  }

  func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
    switch section {
    case 0: return "Product ID"
    case 1: return "Product Title"
    case 2: return "Product Description"
    case 3: return "Price"
    default: return ""
    }
  }

  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return 1
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: Self.cellIdentifier, for: indexPath as IndexPath)
    cell.textLabel?.text = getCellText(section: indexPath.section) ?? ""
    return cell
  }
}
