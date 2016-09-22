// Copyright (c) 2016-present, Facebook, Inc. All rights reserved.
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
import FacebookCore

final class ManualAppEventViewController: UITableViewController {
  @IBOutlet var purchasePriceField: UITextField?
  @IBOutlet var purchaseCurrencyField: UITextField?
  @IBOutlet var itemPriceField: UITextField?
  @IBOutlet var itemCurrencyField: UITextField?
}

//--------------------------------------
// MARK: - Log Purchase
//--------------------------------------

extension ManualAppEventViewController {
  @IBAction func logPurchase() {
    guard
      let priceString = purchasePriceField?.text,
      let price = Double(priceString) else {
        let alertController = UIAlertController(title: "Invalid Purchase Price", message: "Purchase price must be a valid number.")
        present(alertController, animated: true, completion: nil)
        return
    }
    guard let currency = purchaseCurrencyField?.text else {
      let alertController = UIAlertController(title: "Invalid currency", message: "Currency cannot be empty.")
      present(alertController, animated: true, completion: nil)
      return
    }

    let event = AppEvent.purchased(amount: price, currency: currency)
    AppEventsLogger.log(event)
    // View your event at https://developers.facebook.com/analytics/<APP_ID>.
    // See https://developers.facebook.com/docs/analytics for details.

    let alertController = UIAlertController(title: "Log Event", message: "Log Event Success")
    present(alertController, animated: true, completion: nil)
  }
}

//--------------------------------------
// MARK: - Log Add To Cart
//--------------------------------------

extension ManualAppEventViewController {
  @IBAction func logAddToCart() {
    guard
      let priceString = itemPriceField?.text,
      let price = Double(priceString) else {
        let alertController = UIAlertController(title: "Invalid Item Price", message: "Item price must be a valid number.")
        present(alertController, animated: true, completion: nil)
        return
    }
    guard let currency = itemCurrencyField?.text else {
      let alertController = UIAlertController(title: "Invalid currency", message: "Currency cannot be empty.")
      present(alertController, animated: true, completion: nil)
      return
    }

    let event = AppEvent.addedToCart(currency: currency, valueToSum: price)
    AppEventsLogger.log(event)

    let alertController = UIAlertController(title: "Log Event", message: "Log Event Success")
    present(alertController, animated: true, completion: nil)
  }
}
