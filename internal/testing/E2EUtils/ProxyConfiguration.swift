// (c) Meta Platforms, Inc. and affiliates. Confidential and proprietary.

import Foundation

extension URLSessionConfiguration {

  @objc
  public class func _defaultSessionConfiguration() -> URLSessionConfiguration {
    let configuration = URLSessionConfiguration._defaultSessionConfiguration()
    let environment = ProcessInfo.processInfo.environment

    guard let proxyHost = environment["LAB_PROXY_HOST"],
          let proxyPortString = environment["LAB_PROXY_PORT"],
          let proxyPort = Int(proxyPortString)
    else {
      return configuration
    }

    configuration.connectionProxyDictionary = [
      "HTTPEnable": 1,
      "HTTPProxy": proxyHost,
      "HTTPPort": proxyPort,
      "HTTPSProxy": proxyHost,
      "HTTPSPort": proxyPort,
    ]

    return configuration
  }
}

extension NSObject {
  @objc public class func _facebookDomainPart() -> String? {
    let environment = ProcessInfo.processInfo.environment

    guard let sandbox = environment["USER_DEFAULT_FBSandboxSubdomain"] else {
      return nil
    }
    return sandbox.replacingOccurrences(of: ".facebook.com", with: "")
  }
}
