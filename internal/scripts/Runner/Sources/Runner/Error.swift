// (c) Meta Platforms, Inc. and affiliates. Confidential and proprietary.

import Foundation

enum Error: Swift.Error {
    case directoryNavigationFailure
    case missingEverstoreHandle
    case podspecSHA1Generation
    case xcodebuildFailure
}
