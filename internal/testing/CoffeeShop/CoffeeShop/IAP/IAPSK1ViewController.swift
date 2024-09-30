// (c) Meta Platforms, Inc. and affiliates. Confidential and proprietary.

import UIKit

class IAPSK1ViewController: IAPSKViewController {

  override func viewDidLoad() {
    super.viewDidLoad()
    navigationItem.title = "StoreKit 1 IAP"
  }

  override func getStoreVC() -> UIViewController {
    return SK1StoreViewController()
  }

  override func getPurchasesVC() -> UIViewController {
    return SK1PurchasesViewController()
  }
}
