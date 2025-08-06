// (c) Meta Platforms, Inc. and affiliates. Confidential and proprietary.

import UIKit

class IAPSKViewController: UIViewController {

  var containerView: UIView!

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .white
    let segmentedControl = buildSegmentedControl()
    let y = segmentedControl.frame.minY + segmentedControl.frame.height + 10
    let containerViewFrame = CGRectMake(0, y, view.frame.width, view.frame.height - y)
    containerView = UIView(frame: containerViewFrame)
    containerView.backgroundColor = .white
    view.addSubview(containerView)
    view.addSubview(segmentedControl)
    switchViewController(segmentIndex: 0)
    navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Restore", style: .plain, target: self, action: #selector(restorePurchases))
    navigationItem.rightBarButtonItem?.accessibilityIdentifier = "restore-bar-button"
  }

  @objc func restorePurchases() {
    fatalError("Must Override")
  }

  func getStoreVC() -> UIViewController {
    fatalError("Must Override")
  }

  func getPurchasesVC() -> UIViewController {
    fatalError("Must Override")
  }

  private func buildSegmentedControl() -> UISegmentedControl {
    let items = ["Store", "Purchases"]
    let segmentedControl = UISegmentedControl(items: items)
    segmentedControl.selectedSegmentIndex = 0
    let width = 200.0
    let height = 30.0
    let x = (view.frame.width / 2.0) - (width / 2)
    let y = view.frame.minY + 100
    segmentedControl.frame = CGRectMake(x, y, width, height)
    segmentedControl.layer.cornerRadius = 5.0
    segmentedControl.backgroundColor = .lightGray
    segmentedControl.tintColor = UIColor.white
    segmentedControl.addTarget(self, action: #selector(changeSegment), for: .valueChanged)
    return segmentedControl
  }

  @objc func changeSegment(sender: UISegmentedControl) {
    switchViewController(segmentIndex: sender.selectedSegmentIndex)
  }

  private func switchViewController(segmentIndex: Int) {
    switch segmentIndex {
    case 0:
      removeViewController(getPurchasesVC())
      addViewController(getStoreVC())
    case 1:
      removeViewController(getStoreVC())
      addViewController(getPurchasesVC())
    default:
      removeViewController(getPurchasesVC())
      addViewController(getStoreVC())
    }
  }

  private func addViewController(_ viewController: UIViewController) {
    addChild(viewController)
    viewController.view.translatesAutoresizingMaskIntoConstraints = false
    viewController.view.frame = containerView.bounds
    containerView.addSubview(viewController.view)

    NSLayoutConstraint.activate([viewController.view.topAnchor.constraint(equalTo: containerView.safeAreaLayoutGuide.topAnchor),
                                 viewController.view.bottomAnchor.constraint(equalTo: containerView.safeAreaLayoutGuide.bottomAnchor),
                                 viewController.view.leadingAnchor.constraint(equalTo: containerView.safeAreaLayoutGuide.leadingAnchor),
                                 viewController.view.trailingAnchor.constraint(equalTo: containerView.safeAreaLayoutGuide.trailingAnchor)])
    viewController.didMove(toParent: self)
  }

  private func removeViewController(_ viewController: UIViewController) {
    viewController.willMove(toParent: nil)
    viewController.view.removeFromSuperview()
    viewController.removeFromParent()
  }
}

extension UIViewController {
  func alert(with title: String, message: String, handler: (() -> Void)? = nil) {
    let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
    let action = UIAlertAction(title: "OK", style: .cancel, handler: { alert in
      if let handler { handler() }
    })
    alertController.addAction(action)
    navigationController?.present(alertController, animated: true, completion: nil)
  }
}
