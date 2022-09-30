// (c) Meta Platforms, Inc. and affiliates. Confidential and proprietary.

import UIKit

class E2EInfoViewController: UIViewController {

  override func viewDidLoad() {
    super.viewDidLoad()

    view.backgroundColor = .white

    let isTestingLabel = UILabel()
    isTestingLabel.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(isTestingLabel)

    let labProxyLabel = UILabel()
    labProxyLabel.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(labProxyLabel)

    let labHostLabel = UILabel()
    labHostLabel.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(labHostLabel)

    let labPortLabel = UILabel()
    labPortLabel.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(labPortLabel)

    let environment = ProcessInfo.processInfo.environment
    let isTesting = environment["IS_TESTING"] ?? "false"
    let isUsingProxy = environment["LAB_PROXY"] ?? "false"
    let proxyHost = environment["LAB_PROXY_HOST"] ?? "nil"
    let proxyPort = environment["LAB_PROXY_PORT"] ?? "nil"

    isTestingLabel.text = "Is E2E testing: \(isTesting)"
    labProxyLabel.text = "Is using E2E lab proxy: \(isUsingProxy)"
    labHostLabel.text = "E2E Proxy Host: \(proxyHost)"
    labPortLabel.text = "E2E Proxy Port: \(proxyPort)"

    NSLayoutConstraint.activate([
      isTestingLabel.topAnchor.constraint(equalTo: view.topAnchor),
      labProxyLabel.topAnchor.constraint(equalTo: isTestingLabel.bottomAnchor),
      labHostLabel.topAnchor.constraint(equalTo: labProxyLabel.bottomAnchor),
      labPortLabel.topAnchor.constraint(equalTo: labHostLabel.bottomAnchor),
    ])
  }
}
