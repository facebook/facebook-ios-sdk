// (c) Meta Platforms, Inc. and affiliates. Confidential and proprietary.

import Foundation

protocol AuthenticationSession {
    init(url: NSURL, completion: (Bool) -> ())
    
    func start() -> Bool
    func cancel() -> Bool
}
