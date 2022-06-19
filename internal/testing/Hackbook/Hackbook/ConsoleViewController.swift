// (c) Meta Platforms, Inc. and affiliates. Confidential and proprietary.

import UIKit

class ConsoleViewController: UIViewController, UITextViewDelegate {

    // MARK: Constants

    lazy var timestampFormatter: DateFormatter = {
        var formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS z"
        return formatter
    }()

    // MARK: Variables

    @IBOutlet var textView: UITextView?

    // MARK: Object Lifecycle

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: View Management

    override func viewDidLoad() {
        super.viewDidLoad()
      title = "Console"
      textView = UITextView(frame: .zero)
      view.addSubview(textView!)
      navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(dismissConsole))

      NotificationCenter.default.addObserver(self,
                                             selector: #selector(consoleDidAddMessageNotification(notification:)),
                                             name: .ConsoleDidAddMessage,
                                             object: Console.sharedInstance())
      updateTextView()
    }

  @objc func dismissConsole() {
    self.navigationController?.dismiss(animated: true, completion: nil)
  }

  override func viewWillLayoutSubviews() {
    super.viewWillLayoutSubviews()

    textView?.frame = self.view.bounds
  }

    // MARK: Helper Methods

    @objc private func consoleDidAddMessageNotification(notification: Notification) {
        updateTextView()
    }

    private func updateTextView() {
        // DateFormatter is not thread safe, but we only need it on the main thread, so assert that.
        assert(Thread.isMainThread, "Can only be called on the main thread.")

        guard let textView = textView else { return }

        let timestampFont = UIFont.boldSystemFont(ofSize: textView.font?.pointSize ?? 13)
        let timestampAttributes: [NSAttributedString.Key: Any] = [.font: timestampFont]

        let attributedText = NSMutableAttributedString()

        for message in (Console.sharedInstance()?.allMessages as? [ConsoleMessage])?.reversed() ?? [] {
            let timestamp = timestampFormatter.string(from: message.timestamp)
            attributedText.append(NSAttributedString(string: timestamp, attributes: timestampAttributes))
            attributedText.append(NSAttributedString(string: ": \(message.message ?? "")\n"))
        }

        textView.attributedText = attributedText
    }
}
