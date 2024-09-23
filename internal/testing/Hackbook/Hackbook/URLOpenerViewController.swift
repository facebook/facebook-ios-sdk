// (c) Meta Platforms, Inc. and affiliates. Confidential and proprietary.

import UIKit

class URLOpenerViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
  let options = ["Open URL in browser", "Open deeplink"]

  @IBOutlet var tableView: UITableView!

  override func viewDidLoad() {
    super.viewDidLoad()

    // Set up table view
    title = "URL Opener"
    tableView.delegate = self
    tableView.dataSource = self
    tableView.register(UITableViewCell.self, forCellReuseIdentifier: "URLOpenerCell")
  }

  func numberOfSections(in tableView: UITableView) -> Int {
    return 1
  }

  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return options.count
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "URLOpenerCell", for: indexPath)
    cell.selectionStyle = .none
    cell.textLabel?.text = options[indexPath.row]
    return cell
  }

  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    switch indexPath.row {
    case 0: openURLInBrowser()
    case 1: openDeeplink()
    default: break
    }
  }

  private func openURLInBrowser() {
    // Expected to open the URL successfully without warnings in browser when built
    // against XCode 16+. The UIApplication.open API was broken in XCode 16 and Swift
    // only. There is more context in D63081488.
    // Test this specifically in Swift to ensure the API is not broken.
    UIApplication.shared.open(URL(string: "https://www.facebook.com")!)
  }

  private func openDeeplink() {
    // Expected to open coffeeshop app successfully without warnings when built
    // against XCode 16+ and coffeeshop app is installed. The UIApplication.open API
    // was broken in XCode 16 and Swift only. There is more context in D63081488.
    // Test this specifically in Swift to ensure the API is not broken.
    UIApplication.shared.open(URL(string: "fb2020399148181142://CoffeeSearch?coffeeId=12345&al_applink_data=abc")!)
  }
}
