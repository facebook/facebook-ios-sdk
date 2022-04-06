/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import FBSDKCoreKit
import Foundation

struct ChooseContextDialogURLFactory: DialogDeeplinkURLCreating {

  private enum URLValues {
    static let host = "fb.gg"
    static let path = "/dialog/choosecontext/"
  }

  private enum QueryKeys {
    static let filter = "filter"
    static let minSize = "min_size"
    static let maxSize = "max_size"
  }

  var content: ChooseContextContent
  var appID: String

  init(appID: String, content: ChooseContextContent) {
    self.appID = appID
    self.content = content
  }

  func generateDialogDeeplinkURL() throws -> URL {
    var components = URLComponents()
    components.scheme = URLScheme.https.rawValue
    components.host = URLValues.host
    components.path = "\(URLValues.path)\(appID)"

    components.queryItems = [
      URLQueryItem(name: QueryKeys.filter, value: ChooseContextContent.filtersName(forFilters: content.filter)),
      URLQueryItem(name: QueryKeys.minSize, value: String(content.minParticipants)),
      URLQueryItem(name: QueryKeys.maxSize, value: String(content.maxParticipants)),
    ]
    guard let url = components.url else {
      throw GamingServicesDialogError.deeplinkURLCreation
    }
    return url
  }
}
