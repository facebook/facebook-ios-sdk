// (c) Meta Platforms, Inc. and affiliates. Confidential and proprietary.

import UIKit

@MainActor
@available(iOS 15.0, *)
class SK2PurchasesViewController: UIViewController {

  var tableView = UITableView()
  var transactions: [Transaction] = []
  var purchasedProducts: [Product] = []
  private static let cellIdentifier = "SK2PurchaseCell"

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .white
    setupTableView()
    SK2StoreManager.shared.delegate = self
    Task {
      await SK2StoreManager.shared.fetchPurchases()
      await refreshTransactions()
      tableView.reloadData()
    }
  }

  private func refreshTransactions() async {
    transactions = SK2StoreManager.shared.purchases
    let productIDs = transactions.map {
      $0.productID
    }
    purchasedProducts = await SK2StoreManager.shared.fetchProducts(productIdentifiers: productIDs)
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
extension SK2PurchasesViewController: UITableViewDelegate {
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    let product = purchasedProducts[indexPath.row]
    let detailVC = SKProductDetailViewController()
    detailVC.productID = product.id
    detailVC.productTitle = product.displayName
    detailVC.productDescription = product.description
    detailVC.price = "\(product.displayPrice)"
    detailVC.modalPresentationStyle = .pageSheet
    navigationController?.present(detailVC, animated: true, completion: nil)
  }
}

@MainActor
@available(iOS 15.0, *)
extension SK2PurchasesViewController: UITableViewDataSource {
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return purchasedProducts.count
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let product = purchasedProducts[indexPath.row]
    let cell = UITableViewCell(style: .subtitle, reuseIdentifier: Self.cellIdentifier)
    cell.textLabel?.text = product.displayName
    let price = "\(product.displayPrice)"
    cell.detailTextLabel?.text = price
    return cell
  }
}

@MainActor
@available(iOS 15.0, *)
extension SK2PurchasesViewController: SK2StoreManagerUpdatesDelegate {
  func didFailToRestoreTransactions() async {
    alert(with: "Restore Failed", message: "Failed to restore purchases")
  }

  func didRestoreTransactions() async {
    await refreshTransactions()
    tableView.reloadData()
    alert(with: "Succesfully Restored Purchases", message: "Your purchases have been restored")
  }

  func didReceiveUpdatedTransactions() async {
    await refreshTransactions()
    tableView.reloadData()
  }
}
