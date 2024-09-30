// (c) Meta Platforms, Inc. and affiliates. Confidential and proprietary.

import SafariServices
import UIKit
import WebKit

class ProductsListTableViewController: UITableViewController {
  static let numOfProducts: Int32 = 15
  let segueName = "showDetail"
  let cellIdentifier = "productListCell"

  let allProducts: [Coffee] = Coffee.getRandomCoffeeProducts(numOfProducts) as! [Coffee]
  var selectedProduct: Coffee!

  override func viewDidLoad() {
    super.viewDidLoad()

    title = "All Products"
    tableView.showsVerticalScrollIndicator = false
    navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Debug", style: .plain, target: self, action: #selector(showDebugMenu))
    navigationItem.leftBarButtonItem?.accessibilityIdentifier = "debug-bar-button"
    navigationItem.rightBarButtonItem = UIBarButtonItem(title: "IAP", style: .plain, target: self, action: #selector(showIAPMenu))
    navigationItem.rightBarButtonItem?.accessibilityIdentifier = "iap-bar-button"
  }

  @objc func showDebugMenu() {
    let url = URL(string: "https://www.facebook.com")!

    let alert = UIAlertController(title: "Please choose debug function", message: nil, preferredStyle: .actionSheet)
    alert.addAction(UIAlertAction(title: "Open login page", style: .default, handler: { [weak self] _ in
      self?.showLogin()
    }))
    alert.addAction(UIAlertAction(title: "Open web page in WKWebView", style: .default, handler: { [weak self] _ in
      self?.showWKWebView(url)
    }))
    alert.addAction(UIAlertAction(title: "Open web page in SFSafariViewController", style: .default, handler: { [weak self] _ in
      self?.showSFSafariViewController(url)
    }))
    alert.addAction(UIAlertAction(title: "Consent Form Demo", style: .default, handler: { _ in
      self.showConsentForm()
    }))
    alert.addAction(UIAlertAction(title: "Set Sandbox", style: .default, handler: { _ in
      self.showSetSandbox()
    }))
    alert.addAction(UIAlertAction(title: "Raise FBSDKError", style: .destructive, handler: { _ in
      TestUtils.raiseFBSDKError()
    }))

    alert.addAction(UIAlertAction(title: "Raise SIG_TRAP", style: .destructive, handler: { _ in
      DispatchQueue.global().async {
        let a: String! = nil
        print("Crash the app with swift exception: \(a!)")
      }
    }))
    alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
    alert.popoverPresentationController?.sourceView = view
    present(alert, animated: true, completion: nil)
  }

  @objc func showIAPMenu() {
    let alert = UIAlertController(title: "Please Choose IAP Implementation", message: nil, preferredStyle: .actionSheet)
    alert.addAction(UIAlertAction(title: "StoreKit 1", style: .default, handler: { [weak self] _ in
      self?.showStoreKit1()
    }))
    alert.addAction(UIAlertAction(title: "StoreKit 2", style: .default, handler: { [weak self] _ in
      self?.showStoreKit2()
    }))
    alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
    alert.popoverPresentationController?.sourceView = view
    present(alert, animated: true, completion: nil)
  }

  @objc func showStoreKit1() {
    let vc = IAPSK1ViewController()
    navigationController?.pushViewController(vc, animated: true)
  }

  @objc func showStoreKit2() {
    let vc = IAPSK2ViewController()
    navigationController?.pushViewController(vc, animated: true)
  }

  @objc func showLogin() {
    let vc = LoginViewController()
    navigationController?.pushViewController(vc, animated: true)
  }

  @objc func showSetSandbox() {
    let vc = SandboxViewController()
    navigationController?.pushViewController(vc, animated: true)
  }

  @objc func showTestView() {
    let testVC = TestViewController()
    navigationController?.pushViewController(testVC, animated: true)
  }

  func showWKWebView(_ url: URL) {
    let vc = UIViewController()
    vc.title = "WKWebView"

    let vWeb = WKWebView(frame: .zero)
    vWeb.translatesAutoresizingMaskIntoConstraints = false
    vc.view.addSubview(vWeb)

    vc.view.addConstraints(
      NSLayoutConstraint.constraints(
        withVisualFormat: "H:|[web]|",
        options: [],
        metrics: nil,
        views: ["web": vWeb]
      )
    )
    vc.view.addConstraints(
      NSLayoutConstraint.constraints(
        withVisualFormat: "V:|[web]|",
        options: [],
        metrics: nil,
        views: ["web": vWeb]
      )
    )
    vWeb.load(URLRequest(url: url))

    navigationController?.pushViewController(vc, animated: true)
  }

  func showSFSafariViewController(_ url: URL) {
    let vc = SFSafariViewController(url: url)
    present(vc, animated: true, completion: nil)
  }

  func showCoffeeDetail(_ coffeeIndex: Int) {
    selectedProduct = allProducts[coffeeIndex]
    let vc = ProductDetailViewController()
    vc.selectedProduct = selectedProduct
    navigationController?.pushViewController(vc, animated: true)
  }

  func showConsentForm() {
    let consentFormVC = ConsentFormViewController()
    consentFormVC.providesPresentationContextTransitionStyle = true
    consentFormVC.definesPresentationContext = true
    consentFormVC.modalPresentationStyle = .overCurrentContext
    present(consentFormVC, animated: false, completion: nil)
  }

  // MARK: - Table view data source

  override func numberOfSections(in tableView: UITableView) -> Int {
    1
  }

  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    allProducts.count
  }

  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    var cell: UITableViewCell! = tableView.dequeueReusableCell(withIdentifier: cellIdentifier)
    if cell == nil {
      cell = UITableViewCell(style: .value1, reuseIdentifier: cellIdentifier)
    }

    let coffee = allProducts[indexPath.row]
    cell.textLabel?.text = coffee.name
    cell.detailTextLabel?.text = String(format: "%.2f", coffee.price)
    cell.accessibilityIdentifier = "coffee-cell-\(indexPath.row)"

    return cell
  }

  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    showCoffeeDetail(indexPath.row)
  }

  override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
    if section == 0 {
      let header = UIButton()
      let screenSize = UIScreen.main.bounds.size
      header.frame = CGRect(x: 0, y: 0, width: screenSize.width, height: 50)
      header.setTitle("Test", for: .normal)
      header.setTitleColor(.black, for: .normal)
      header.backgroundColor = .white
      header.addTarget(self, action: #selector(showTestView), for: .touchUpInside)
      return header
    }

    return nil
  }

  override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
    section == 0 ? 50 : 0
  }
}
