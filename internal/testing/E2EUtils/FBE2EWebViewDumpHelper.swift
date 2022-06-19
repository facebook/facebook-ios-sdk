// (c) Meta Platforms, Inc. and affiliates. Confidential and proprietary.

import Foundation
import WebKit

public class FBE2EWebViewDumpHelper: UIView {

    @objc public var content: String = ""
    @objc public static let sharedInstance = FBE2EWebViewDumpHelper()

    @objc public var hasContent: Bool {
        !content.isEmpty
    }

    /**
     This is a "best effort" method which fetches content from a WKWebView asynchronously.
     Since this is an expensive call and the view hierarchy dump method will be called multiple
     times in the time it takes for one round-trip, do not wait for it to finish. Instead, the
     caller should not expect any content to be present and and use the hasContent() method
     to confirm. Additionally, the caller should check that the WKWebView is still present in
     the view hierarchy before appending content to the view dump.
    */
    @objc public func extractHtml(from webView: WKWebView) {
        let script = javascriptForHtmlViewDump(webView: webView)
        webView.evaluateJavaScript(script) { (result: Any?, error: Error?) in
            if error != nil {
                NSLog("Unable to parse HMTL: %@", error!.localizedDescription)
            }
            guard let unparsedHtml = result as? String else { return }
            let parsedHtml = self.fixedHtmlString(inputString: unparsedHtml)
            let htmlID = String(format: "%@{%x}", NSStringFromClass(type(of: webView)), UInt(webView.hash))
            let formattedHtml = [
              "<html id=\"\(htmlID)\" data-rect=\"",
              "\(Int(webView.frame.origin.x)),",
              "\(Int(webView.frame.origin.y)),",
              "\(Int(webView.frame.size.width)),",
              "\(Int(webView.frame.size.height))",
              "\">\(parsedHtml)</html>"
            ].joined()
            self.content = formattedHtml
        }
    }

    func javascriptForHtmlViewDump(webView: WKWebView) -> String {
        """
        (function() { \
            try { \
              const leftOf = \(Int(webView.frame.origin.x)); \
              const topOf = \(Int(webView.frame.origin.y)); \
              const density = 1.0; \
              const elements = Array.from(document.querySelectorAll('body, body *')); \
              for (const el of elements) { \
                const rect = el.getBoundingClientRect(); \
                const left = Math.round(leftOf + rect.left * density); \
                const top = Math.round(topOf + rect.top * density); \
                const width = Math.round(rect.width * density); \
                const height = Math.round(rect.height * density); \
                el.setAttribute('data-rect', `${left},${top},${width},${height}`); \
                const style = window.getComputedStyle(el); \
                const hidden = style.display === 'none' || style.visibility !== 'visible' || el.getAttribute('hidden') === 'true'; \
                const disabled = el.disabled || el.getAttribute('aria-disabled') === 'true'; \
                const focused = el === document.activeElement; \
                if (hidden || disabled || focused) { \
                  el.setAttribute('data-flag', `${hidden ? 'H' : ''}${disabled ? 'D' : ''}${focused ? 'F' : ''}`); \
                } else { \
                  el.removeAttribute('data-flag'); \
                } \
              } \
              document.activeElement.setAttribute('focused', 'true'); \
              const doc = document.cloneNode(true); \
              for (const el of Array.from(doc.querySelectorAll('script, link'))) { \
                el.remove(); \
              } \
              for (const el of Array.from(doc.querySelectorAll('*'))) { \
                el.removeAttribute('class'); \
              } \
              return doc.getElementsByTagName('body')[0].outerHTML.trim(); \
            } catch (e) { \
              return 'Failed: ' + e; \
            } \
        })();
        """
    }

    func fixedHtmlString(inputString: String) -> String {
        var fixedString = inputString
        fixedString = fixedString.replacingOccurrences(of: "\\u003C", with: "<")
        fixedString = fixedString.replacingOccurrences(of: "\\n", with: "")
        fixedString = fixedString.replacingOccurrences(of: "\\\"", with: "\"")
        let lowerBound = fixedString.index(fixedString.startIndex, offsetBy: 1)
        return String(fixedString[lowerBound..<fixedString.endIndex])
    }
}
