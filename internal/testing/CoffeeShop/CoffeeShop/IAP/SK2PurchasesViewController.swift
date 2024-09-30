// (c) Meta Platforms, Inc. and affiliates. Confidential and proprietary.

import UIKit

class SK2PurchasesViewController: UIViewController {

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .white
    let width = 200.0
    let height = 30.0
    let x = (view.frame.width / 2.0) - (width / 2)
    let label = UILabel(frame: CGRect(x: x, y: 200, width: width, height: height))
    label.textAlignment = .center
    label.text = "StoreKit 2 Purchases!"
    view.addSubview(label)
  }
}
