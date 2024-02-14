// (c) Meta Platforms, Inc. and affiliates. Confidential and proprietary.

import UIKit

class DomainConfigurationTestViewController: UIViewController {

  @IBOutlet var domainConfigurationTextView: UITextView!

  override func viewDidLoad() {
    super.viewDidLoad()
    if let domainConfig = _DomainConfigurationManager.sharedInstance().cachedDomainConfiguration().domainInfo {
      let formattedDict = NSDictionary(dictionary: domainConfig)
      domainConfigurationTextView.text = "\(formattedDict)"
    } else {
      domainConfigurationTextView.text = "Failed to fetch the domain configuration"
    }
  }
}
