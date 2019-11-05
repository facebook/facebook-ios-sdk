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

import Foundation
import UIKit

class RPSAutoAppLinkSwiftViewController: UIViewController, AutoAppLink {
    var product: Coffee?
    var data: Dictionary<String, Any>?

    let paddingLen: CGFloat = 10
    let frameHeight: CGFloat = 30

    override func viewDidLoad() {
        super.viewDidLoad()

        self.view.backgroundColor = UIColor.white
        let scrolllView: UIScrollView = UIScrollView(frame: CGRect(x: 0, y: 0, width: self.view.frame.size.width, height: self.view.frame.size.height))
        let frameWidth = scrolllView.frame.size.width - paddingLen*2

        let nameLabel: UILabel = UILabel(frame: CGRect(x: paddingLen, y: 50, width: frameWidth, height: frameHeight))
        nameLabel.font = UIFont.boldSystemFont(ofSize: 24)
        nameLabel.textColor = UIColor.gray

        let descLabel:UILabel = UILabel(frame: CGRect(x: paddingLen, y: 90, width: frameWidth, height: frameHeight + 10))
        descLabel.font = UIFont.systemFont(ofSize: 14)
        descLabel.textColor = UIColor.lightGray
        descLabel.numberOfLines = 0

        let priceLabel:UILabel = UILabel(frame: CGRect(x: paddingLen, y: 140, width: frameWidth, height: frameHeight - 10))
        priceLabel.font = UIFont.systemFont(ofSize: 20)
        priceLabel.textColor = UIColor.lightGray

        if self.product == nil {
            self.product = Coffee(name: "SWIFT Coffee", desc: "I am just a SWIFT coffee", price: 1)
        }
        nameLabel.text = self.product!.name
        descLabel.text = "Description: " + self.product!.desc
        priceLabel.text = "Price: $" + self.product!.price.description

        scrolllView.addSubview(nameLabel)
        scrolllView.addSubview(descLabel)
        scrolllView.addSubview(priceLabel)

        if let data = self.data {
            let dataLabel: UILabel = UILabel()
            dataLabel.font = UIFont.systemFont(ofSize: 20)
            dataLabel.textColor = UIColor.blue
            dataLabel.text = String.init(format: "data is: %@", data)
            dataLabel.numberOfLines = 0
            let size: CGSize = (dataLabel.text! as NSString).boundingRect(with: CGSize(width: frameWidth, height: 1000), options: .usesLineFragmentOrigin, attributes: [.font: dataLabel.font!], context: nil).size
            dataLabel.frame = CGRect(x: paddingLen, y: 190, width: size.width, height: size.height)
            scrolllView.addSubview(dataLabel)
        }
        self.view.addSubview(scrolllView)
    }

    // Auto App Link delegate function, you can get the Auto App Link data in this function
    // present your view controller with the data
    @objc func setAutoAppLinkData(_ data: Dictionary<String, Any>)
    {
        let productIndex = String.init(format: "%d", data["product_id"] as! Int)
        let name = "SWIFT Coffee " + productIndex
        let description = "I am auto app link SWIFT coffee " + productIndex
        self.product = Coffee(name: name, desc: description, price: 10)
        self.data = data
    }
}
