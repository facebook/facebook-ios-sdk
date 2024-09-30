// (c) Meta Platforms, Inc. and affiliates. Confidential and proprietary.

import UIKit

class SK1PurchasesViewController: UIViewController {

  var tableView = UITableView()
  var transactions: [SKPaymentTransaction] = []
  var purchasedProducts: [SKProduct] = []
  private static let cellIdentifier = "SK1PurchaseCell"

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .white
    setupTableView()
    SK1StoreManager.shared.productFetchingDelegate = self
    SK1StoreManager.shared.productPurchasingDelegate = self
    refreshTransactions()
  }

  private func refreshTransactions() {
    transactions = SK1StoreManager.shared.purchases + SK1StoreManager.shared.restored
    let productIDs = transactions.map {
      $0.payment.productIdentifier
    }
    SK1StoreManager.shared.fetchProducts(productIdentifiers: productIDs)
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

extension SK1PurchasesViewController: UITableViewDelegate {
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    let product = purchasedProducts[indexPath.row]
    let detailVC = SKProductDetailViewController()
    detailVC.productID = product.productIdentifier
    detailVC.productTitle = product.localizedTitle
    detailVC.productDescription = product.localizedDescription
    detailVC.price = "\(product.price)\(product.priceLocale.currencySymbol ?? "$")"
    detailVC.modalPresentationStyle = .pageSheet
    navigationController?.present(detailVC, animated: true, completion: nil)
  }
}

extension SK1PurchasesViewController: UITableViewDataSource {
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return purchasedProducts.count
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let product = purchasedProducts[indexPath.row]
    let cell = UITableViewCell(style: .subtitle, reuseIdentifier: Self.cellIdentifier)
    cell.textLabel?.text = product.localizedTitle
    let price = "\(product.price)\(product.priceLocale.currencySymbol ?? "$")"
    cell.detailTextLabel?.text = price
    return cell
  }
}

extension SK1PurchasesViewController: SK1StoreManagerProductFetchingDelegate {
  func didFetchProducts(_ products: [SKProduct]) {
    purchasedProducts = products
    tableView.reloadData()
  }
}

extension SK1PurchasesViewController: SK1StoreManagerProductPurchasingDelegate {
  func purchaseDidSucceed(_ transaction: SKPaymentTransaction) {}

  func purchaseDidFail(_ transaction: SKPaymentTransaction) {}

  func restoreDidFail(withError: any Error) {
    let message = "Failed to restore purchases with error: \(withError.localizedDescription)"
    alert(with: "Restore Failed", message: message)
  }

  func notifyRestoreDidSucceed() {
    refreshTransactions()
    alert(with: "Succesfully Restored Purchases", message: "Your purchases have been restored")
  }

  func notifyNoRestoredPurchases() {
    alert(with: "No Purchases to Restore", message: "You have no purchases to restore")
  }
}
