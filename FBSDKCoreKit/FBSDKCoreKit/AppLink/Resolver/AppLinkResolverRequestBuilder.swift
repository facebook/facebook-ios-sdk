/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

/**
 Class responsible for generating the appropriate GraphRequest for a given set of urls
 */
final class AppLinkResolverRequestBuilder: NSObject, _AppLinkResolverRequestBuilding {

  private enum IdiomField: String {
    case ios
    case iphone
    case ipad
    case appLinks = "app_links"
  }

  private let userInterfaceIdiom: UIUserInterfaceIdiom
  private var uiSpecificFields: [String] {
    var fields = [IdiomField.ios.rawValue]

    if let idiomSpecificField = getIdiomSpecificField() {
      fields.append(idiomSpecificField)
    }

    return fields
  }

  init(userInterfaceIdiom: UIUserInterfaceIdiom = UIDevice.current.userInterfaceIdiom) {
    self.userInterfaceIdiom = userInterfaceIdiom
  }

  func request(for urls: [URL]) -> GraphRequestProtocol {
    let fields = uiSpecificFields.joined(separator: ",")
    let encodedURLs = getEncodedURLs(urls).joined(separator: ",")

    let path = "?fields=\(IdiomField.appLinks.rawValue).fields(\(fields))&ids=\(encodedURLs)"
    return GraphRequest(
      graphPath: path,
      parameters: nil,
      flags: [.doNotInvalidateTokenOnError, .disableErrorRecovery]
    )
  }

  func getIdiomSpecificField() -> String? {
    switch userInterfaceIdiom {
    case .pad: return IdiomField.ipad.rawValue
    case .phone: return IdiomField.iphone.rawValue
    default: return nil
    }
  }

  private func getEncodedURLs(_ urls: [URL]) -> [String] {
    urls.compactMap {
      $0.absoluteString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
    }
  }
}
