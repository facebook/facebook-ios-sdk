// (c) Meta Platforms, Inc. and affiliates. Confidential and proprietary.

import StoreKit
import UIKit

@MainActor
@available(iOS 15.0, *)
class SK2StoreViewController: UIViewController {

  var tableView = UITableView()
  var products: [Product] = []
  private static let cellIdentifier = "SK2StoreCell"

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .white
    setupTableView()
    Task {
      products = await SK2StoreManager.shared.fetchProducts()
      tableView.reloadData()
    }
  }

  private func setupTableView() {
    tableView.register(UITableViewCell.self, forCellReuseIdentifier: Self.cellIdentifier)
    tableView.delegate = self
    tableView.dataSource = self
    view.addSubview(tableView)
    tableView.translatesAutoresizingMaskIntoConstraints = false
    tableView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
    tableView.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
    tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
    tableView.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
  }
}

@MainActor
@available(iOS 15.0, *)
extension SK2StoreViewController: UITableViewDelegate {
  private func handleFailedPurchase(product: Product) {
    AppEvents.shared.logFailedStoreKit2Purchase(product.id)
    let message = "Failed to purchase the \(product.displayName)"
    alert(with: "Purchase Failed", message: message)
  }

  private func handleSuccessPurchase(product: Product) {
    let message = "You successfully purchased the \(product.displayName)"
    alert(with: "Purchase Success", message: message)
  }

  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    let product = products[indexPath.row]
    Task {
      let result = await SK2StoreManager.shared.buy(product: product)
      switch result {
      case .failed: handleFailedPurchase(product: product)
      case .success: handleSuccessPurchase(product: product)
      case .pending: break
      }
    }
  }
}

@MainActor
@available(iOS 15.0, *)
extension SK2StoreViewController: UITableViewDataSource {
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return products.count
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let product = products[indexPath.row]
    let cell = UITableViewCell(style: .subtitle, reuseIdentifier: Self.cellIdentifier)
    cell.textLabel?.text = product.displayName
    let price = "\(product.displayPrice)"
    cell.detailTextLabel?.text = price
    return cell
  }
}

@MainActor
@available(iOS 15.0, *)
extension SK2StoreViewController: SK2StoreManagerUpdatesDelegate {
  func didFailToRestoreTransactions() async {
    alert(with: "Restore Failed", message: "Failed to restore purchases")
  }

  func didRestoreTransactions() async {
    alert(with: "Succesfully Restored Purchases", message: "Your purchases have been restored")
  }

  func didReceiveUpdatedTransactions() async {}
}
