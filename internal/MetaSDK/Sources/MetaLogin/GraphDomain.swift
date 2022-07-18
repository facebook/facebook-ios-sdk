// (c) Meta Platforms, Inc. and affiliates. Confidential and proprietary.

import Foundation

/// It represents login account type (Facebook/Meta)
public enum GraphDomain: String, Codable {
    /// Login with Facebook account
    case faceBook = "FaceBook"
    /// Login with Meta account
    case meta = "Meta"
}
