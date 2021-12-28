/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

@objcMembers
public class TestBridgeAPIRequest: NSObject, BridgeAPIRequestProtocol {
  public var actionID: String
  public var methodName: String?
  public var protocolType: FBSDKBridgeAPIProtocolType
  public var `protocol`: BridgeAPIProtocol?
  public var scheme: String

  public let url: URL?

  public init(url: URL?, protocolType: FBSDKBridgeAPIProtocolType = .native, scheme: String = "1") {
    self.url = url
    self.protocolType = protocolType
    self.scheme = scheme
    actionID = "1"
  }

  public func copy(with zone: NSZone? = nil) -> Any {
    self
  }

  public func requestURL() throws -> URL {
    guard let url = url else {
      throw FakeBridgeAPIRequestError(domain: "tests", code: 0, userInfo: [:])
    }
    return url
  }

  public static func request(withURL url: URL?) -> TestBridgeAPIRequest {
    TestBridgeAPIRequest(url: url)
  }

  public static func request(withURL url: URL, scheme: String) -> TestBridgeAPIRequest {
    TestBridgeAPIRequest(url: url, scheme: scheme)
  }
}

@objc
public class FakeBridgeAPIRequestError: NSError {}
