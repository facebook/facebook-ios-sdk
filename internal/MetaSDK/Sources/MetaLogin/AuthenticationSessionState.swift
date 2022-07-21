// (c) Meta Platforms, Inc. and affiliates. Confidential and proprietary.

import Foundation

enum AuthenticationSessionState: Int {
    /// no login session has started
    case none
    /// login session has started and user is performing login
    case performingLogin
    /// login session was canceled
    case canceled
}
