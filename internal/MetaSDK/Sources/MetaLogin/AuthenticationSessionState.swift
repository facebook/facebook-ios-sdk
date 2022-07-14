// (c) Meta Platforms, Inc. and affiliates. Confidential and proprietary.

import Foundation

enum AuthenticationSessionState: Equatable {
    /// no active authentication session
    case none
    /// authentication session has started
    case started
    /// system dialog: “app wants to use meta.com to sign in” was presented to user
    case showingSystemDialog
    /// web browser with login to authentication was presented to user
    case showWebBrowser
    /// authentication session was canceled; takes in an associated value to clarify reason why session was canceled
    case canceled(reason: String)
}
