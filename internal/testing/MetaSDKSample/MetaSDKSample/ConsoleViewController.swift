/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import UIKit

class ConsoleViewController: UIViewController, UITextViewDelegate, ConsoleDataProviding {

  @IBOutlet var textView: UITextView!

  override func viewDidLoad() {
    super.viewDidLoad()

    textView.delegate = self
    title = "Console"
    navigationItem.rightBarButtonItem = UIBarButtonItem(
      barButtonSystemItem: .done,
      target: self,
      action: #selector(dismissConsole)
    )
    updateTextView()
  }

  @objc func dismissConsole() {
    self.navigationController?.dismiss(animated: true, completion: nil)
  }

  private func updateTextView() {

    let attributedText = NSMutableAttributedString()

    for message in self.consoleDataManager.allMessages() {
      attributedText.append(NSAttributedString(string: "\(message)\n"))
    }
    textView.attributedText = attributedText
  }
}
