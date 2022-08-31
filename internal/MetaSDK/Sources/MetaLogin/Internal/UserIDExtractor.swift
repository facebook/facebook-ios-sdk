/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import Foundation

struct UserIDExtractor {
  func getUserID(from signedRequest: String) -> UInt? {
    let signatureAndPayload = signedRequest.components(separatedBy: ".")
    var userID = ""

    if signatureAndPayload.count == 2 {
      var payload = signatureAndPayload[1] as String
      let remainder = payload.count % 4
      if remainder > 0 {
        payload = payload.padding(
          toLength: payload.count + 4 - remainder,
          withPad: "=",
          startingAt: 0
        )
      }
      if let data = Data(base64Encoded: payload, options: .ignoreUnknownCharacters),
         let dictionary = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
        userID = dictionary["user_id"] as? String ?? ""
      }
    }

    if userID.isEmpty {
      return nil
    }
    return UInt(userID)
  }
}
