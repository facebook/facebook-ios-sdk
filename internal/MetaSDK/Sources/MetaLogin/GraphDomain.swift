/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import Foundation

/// It represents login account type (Facebook/Meta)
public enum GraphDomain: String, Codable {
    /// Login with Facebook account
    case faceBook = "FaceBook"
    /// Login with Meta account
    case meta = "Meta"
}
