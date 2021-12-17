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

  public var validateURLSchemesCalled = false
  public var isFacebookAppInstalled = false
  public var isMessengerAppInstalled = false
  public var stubbedURL: URL?
  public var stubbedAppURL: URL?
  public var stubbedFacebookURL: URL?
  public var capturedURLScheme: String?
  public var capturedURLHost: String?
  public var capturedURLPath: String?
  public var capturedURLQueryParameters: [String: String]?
  public var capturedAppURLHost: String?
  public var capturedAppURLPath: String?
  public var capturedAppURLQueryParameters: [String: String]?
  public var capturedFacebookURLHostPrefix: String?
  public var capturedFacebookURLPath: String?
  public var capturedFacebookURLQueryParameters: [String: String]?
  public var capturedExtensibleParameters: NSMutableDictionary?
  public var isUnity = false
  public var appURLScheme = ""

  public func url(
    withScheme scheme: String,
    host: String,
    path: String,
    queryParameters: [String: String]
  ) throws -> URL {
    capturedURLScheme = scheme
    capturedURLHost = host
    capturedURLPath = path
    capturedURLQueryParameters = queryParameters

    guard let url = stubbedURL else { throw SampleError() }
    return url
  }

  public func facebookURL(
    withHostPrefix hostPrefix: String,
    path: String,
    queryParameters: [String: String]
  ) throws -> URL {
    capturedFacebookURLHostPrefix = hostPrefix
    capturedFacebookURLPath = path
    capturedFacebookURLQueryParameters = queryParameters

    guard let url = stubbedFacebookURL else { throw SampleError() }
    return url
  }

  public func appURL(
    withHost host: String,
    path: String,
    queryParameters: [String: String]
  ) throws -> URL {
    capturedAppURLHost = host
    capturedAppURLPath = path
    capturedAppURLQueryParameters = queryParameters

    guard let url = stubbedAppURL else { throw SampleError() }
    return url
  }

  public func registerTransientObject(_ object: Any) {}

  public func unregisterTransientObject(_ object: Any) {}

  public func checkRegisteredCanOpenURLScheme(_ urlScheme: String) {}

  public func validateURLSchemes() {
    validateURLSchemesCalled = true
  }

  public func extendDictionary(withDataProcessingOptions parameters: NSMutableDictionary) {
    capturedExtensibleParameters = parameters
  }

  public func hexadecimalString(from data: Data) -> String? {
    nil
  }
}
