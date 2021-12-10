/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import Foundation
import UIKit

class RPSAutoAppLinkSwiftViewController: UIViewController {
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
}
