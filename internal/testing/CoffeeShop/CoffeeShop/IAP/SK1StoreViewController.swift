// (c) Meta Platforms, Inc. and affiliates. Confidential and proprietary.

import UIKit

class SK1StoreViewController: UIViewController {

  var tableView = UITableView()
  var products: [SKProduct] = []
  private static let cellIdentifier = "SK1StoreCell"

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .white
    setupTableView()
    SK1StoreManager.shared.productFetchingDelegate = self
    SK1StoreManager.shared.productPurchasingDelegate = self
    SK1StoreManager.shared.fetchProducts()
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

extension SK1StoreViewController: UITableViewDelegate {
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    let product = products[indexPath.row]
    SK1StoreManager.shared.buy(product: product)
  }
}

extension SK1StoreViewController: UITableViewDataSource {
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return products.count
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let product = products[indexPath.row]
    let cell = UITableViewCell(style: .subtitle, reuseIdentifier: Self.cellIdentifier)
    cell.textLabel?.text = product.localizedTitle
    let price = "\(product.price)\(product.priceLocale.currencySymbol ?? "$")"
    cell.detailTextLabel?.text = price
    return cell
  }
}

extension SK1StoreViewController: SK1StoreManagerProductFetchingDelegate {
  func didFetchProducts(_ products: [SKProduct]) {
    self.products = products
    tableView.reloadData()
  }
}

extension SK1StoreViewController: SK1StoreManagerProductPurchasingDelegate {
  func purchaseDidSucceed(_ transaction: SKPaymentTransaction) {
    var message = "You successfully purchased the item"
    if let product = SK1StoreManager.shared.getProductFor(productID: transaction.payment.productIdentifier) {
      message = "You successfully purchased the \(product.localizedTitle)"
    }
    alert(with: "Purchase Success", message: message)
  }

  func purchaseDidFail(_ transaction: SKPaymentTransaction) {
    var message = "Failed to purchase the item"
    if let product = SK1StoreManager.shared.getProductFor(productID: transaction.payment.productIdentifier) {
      message = "Failed to purchase the \(product.localizedTitle)"
    }
    alert(with: "Purchase Failed", message: message)
  }

  func restoreDidFail(withError: any Error) {
    let message = "Failed to restore purchases with error: \(withError.localizedDescription)"
    alert(with: "Restore Failed", message: message)
  }

  func notifyRestoreDidSucceed() {
    alert(with: "Succesfully Restored Purchases", message: "Your purchases have been restored")
  }

  func notifyNoRestoredPurchases() {
    alert(with: "No Purchases to Restore", message: "You have no purchases to restore")
  }
}
