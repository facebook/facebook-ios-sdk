// Copyright (c) 2014-present, Facebook, Inc. All rights reserved.
//
// You are hereby granted a non-exclusive, worldwide, royalty-free license to use,
// copy, modify, and distribute this software in source code or binary form for use
// in connection with the web services and APIs provided by Facebook.
//
// As with any software that integrates with the Facebook platform, your use of
// this software is subject to the Facebook Developer Principles and Policies
// [http://developers.facebook.com/policy/]. This copyright notice shall be
// included in all copies or substantial portions of the software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
// FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
// COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
// IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
// CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

import UIKit
import FBSDKLoginKit

enum CellType: Int, CaseIterable {
  case status
  case login

  static var count: Int {
      return allCases.count
  }
}

enum CellController {
  static private let loginButton = FBLoginButton()

  static func configure(_ cell: UITableViewCell, ofType type: CellType) {
    switch type {
    case .status:
      configureStatusCell(cell)

    case .login:
      loginButton.removeFromSuperview()
      loginButton.center = cell.contentView.center
      cell.contentView.addSubview(loginButton)
    }
  }

  static func didSelect(_ type: CellType, from viewController:UIViewController) {
    switch type {
    case .status:
      break // no-op

    case .login:
      break // no-op
    }
  }

  static func heightForCell(_ type: CellType) -> CGFloat {
    switch type {
    case .status:
      return 88
    case .login:
      return 44
    }
  }

  private static func configureStatusCell(_ cell: UITableViewCell) {
    if (AccessToken.current == nil) {
      cell.textLabel?.text = "No Access Token, Please Log in"
      cell.textLabel?.textAlignment = .center
      cell.imageView?.image = nil
      return
    }

    GraphRequest(graphPath: "me", parameters: ["fields": "id,name,picture"])
      .start { (connection, result, error) in

        let result = result as? [String: Any]

        let url = ((
          result?["picture"] as? [String: Any]
          )?["data"] as? [String: Any]
          )?["url"] as? String

        let id = result?["id"] as? String
        let name = result?["name"] as? String

        cell.downloadImage(url)

        cell.textLabel?.attributedText =
          NSAttributedString(string:
            """
            ID: \(id ?? "")
            Name: \(name ?? "")
            """)
        cell.textLabel?.numberOfLines = 0
        cell.textLabel?.textAlignment = .left

        cell.setNeedsLayout()
    }
  }
}

extension UITableViewCell {
  func downloadImage(_ link: String?) {
    let url = URL(string: link ?? "")
    if (url == nil) {
      return
    }
    URLSession.shared.dataTask(with: url!) { data, response, error in
      guard
        let httpURLResponse = response as? HTTPURLResponse, httpURLResponse.statusCode == 200,
        let mimeType = response?.mimeType, mimeType.hasPrefix("image"),
        let data = data, error == nil,
        let image = UIImage(data: data)
        else { return }

      DispatchQueue.main.async() {
        self.imageView?.image = image
        self.setNeedsLayout()
      }
    }.resume()
  }
}
