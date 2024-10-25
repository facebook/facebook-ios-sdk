// (c) Meta Platforms, Inc. and affiliates. Confidential and proprietary.

import FBSDKCoreKit
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
    showRestoreTestCasesOptions()
  }

  func showRestoreTestCasesOptions() {
    let alert = UIAlertController(title: "Purchase Restored Test Cases", message: nil, preferredStyle: .actionSheet)
    alert.addAction(UIAlertAction(title: "Test Case 1", style: .default, handler: { [weak self] _ in
      self?.executePurchaseRestoredTestCase1()
    }))
    alert.addAction(UIAlertAction(title: "Test Case 2", style: .default, handler: { [weak self] _ in
      self?.executePurchaseRestoredTestCase2()
    }))
    alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
    alert.popoverPresentationController?.sourceView = view
    present(alert, animated: true, completion: nil)
  }

  private func executePurchaseRestoredTestCase1() {
    UserDefaults.standard.set(false, forKey: "com.facebook.sdk:RestoredPurchasesKey")
  }

  private func executePurchaseRestoredTestCase2() {
    guard let oneDayAgo = Calendar.current.date(byAdding: .day, value: -1, to: Date()) else {
      return
    }
    UserDefaults.standard.removeObject(forKey: "com.facebook.sdk:LoggedTransactionsKey")
    UserDefaults.standard.set(oneDayAgo, forKey: "com.facebook.sdk:NewCandidatesDateKey")
  }
}
