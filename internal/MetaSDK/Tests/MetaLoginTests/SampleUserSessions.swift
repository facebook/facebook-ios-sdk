/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

@testable import MetaLogin
import Foundation

public enum SampleUserSessions {
  public static func example(
    graphDomain: GraphDomain = GraphDomain.facebook
  ) -> UserSession {
    let sampleAccessToken = AccessToken(
      tokenString: SampleRawLoginResponse.accessToken,
      expirationDate: Date().addingTimeInterval(100),
      dataAccessExpirationDate: Date().addingTimeInterval(100)
    )!
    return UserSession(
      userID: SampleRawLoginResponse.userID,
      graphDomain: graphDomain,
      accessToken: sampleAccessToken,
      requestedPermissions: SampleRawLoginResponse.requestedPermissions
    )
  }
}
