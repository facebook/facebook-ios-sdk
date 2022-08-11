/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

/// Values epresenting login account domains
public enum GraphDomain: String, Codable {
  /// For logins using a Facebook account.
  case facebook = "Facebook"
  /// For logins using a Meta account.
  case meta = "Meta"
}
