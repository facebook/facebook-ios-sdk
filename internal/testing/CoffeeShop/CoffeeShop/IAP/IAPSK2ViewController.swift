// (c) Meta Platforms, Inc. and affiliates. Confidential and proprietary.

import UIKit

@MainActor
@available(iOS 15.0, *)
class IAPSK2ViewController: IAPSKViewController {

  override func viewDidLoad() {
    super.viewDidLoad()
    navigationItem.title = "StoreKit 2 IAP"
  }

  override func getStoreVC() -> UIViewController {
    return SK2StoreViewController()
  }

  override func getPurchasesVC() -> UIViewController {
    return SK2PurchasesViewController()
  }

  @objc override func restorePurchases() {
    Task {
      await SK2StoreManager.shared.restorePurchases()
    }
  }
}
