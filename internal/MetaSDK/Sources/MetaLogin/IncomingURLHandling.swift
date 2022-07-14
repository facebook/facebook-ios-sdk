// (c) Meta Platforms, Inc. and affiliates. Confidential and proprietary.

import Foundation

protocol IncomingURLHandling {
    func isAuthenticationURL(url: NSURL) -> Bool
    func handle(url: NSURL, completionHandler: ((Bool) -> ())?) -> Void
}
