// (c) Meta Platforms, Inc. and affiliates. Confidential and proprietary.

import StoreKit
import UIKit

class IAPSK1ViewController: IAPSKViewController {

  override func viewDidLoad() {
    super.viewDidLoad()
    navigationItem.title = "StoreKit 1 IAP"
  }

  override func viewDidAppear(_ animated: Bool) {
    SKPaymentQueue.default().add(SK1StoreManager.shared)
  }

  override func viewDidDisappear(_ animated: Bool) {
    SKPaymentQueue.default().remove(SK1StoreManager.shared)
  }

  override func getStoreVC() -> UIViewController {
    return SK1StoreViewController()
  }

  override func getPurchasesVC() -> UIViewController {
    return SK1PurchasesViewController()
  }

  @objc override func restorePurchases() {
    SK1StoreManager.shared.restorePurchases()
  }
}
