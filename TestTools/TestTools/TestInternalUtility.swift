/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import FBSDKCoreKit
import FBSDKCoreKit_Basics

@objcMembers
public class TestInternalUtility: NSObject,
  AppAvailabilityChecker,
  URLHosting,
  AppURLSchemeProviding,
  InternalUtilityProtocol {

  public var isMSQRDPlayerAppInstalled = false
  public var stubbedScheme = "No stub app url scheme provided"
  public var validateURLSchemesCalled = false
  public var isFacebookAppInstalled = false
  public var isMessengerAppInstalled = false
  public var stubbedURL: URL?

  public func facebookURL(
    withHostPrefix hostPrefix: String,
    path: String,
    queryParameters: [String: Any],
    error errorRef: NSErrorPointer
  ) -> URL {
    stubbedURL ?? URL(string: "facebook.com")! // swiftlint:disable:this force_unwrapping
  }

  public func appURL(
    withHost host: String,
    path: String,
    queryParameters: [String: Any],
    error errorRef: NSErrorPointer
  ) -> URL {
    stubbedURL ?? URL(string: "example.com")! // swiftlint:disable:this force_unwrapping
  }

  public func appURLScheme() -> String {
    stubbedScheme
  }

  public func url(
    withScheme scheme: String,
    host: String,
    path: String,
    queryParameters: [String: Any]
  ) throws -> URL {
    struct Error: Swift.Error {}

    guard let url = stubbedURL else { throw Error() }
    return url
  }

  public func registerTransientObject(_ object: Any) {}

  public func unregisterTransientObject(_ object: Any) {}

  public func checkRegisteredCanOpenURLScheme(_ urlScheme: String) {}

  public func validateURLSchemes() {
    validateURLSchemesCalled = true
  }
}
