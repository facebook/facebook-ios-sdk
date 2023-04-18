/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import Foundation

import FBSDKCoreKit_Basics
import UIKit

enum SettingsAPIFields: String {
  case url = "endpoint"
  case enabled = "is_enabled"
  case datasetID = "dataset_id"
  case accessKey = "access_key"
}

public typealias AppEventsCAPIManager = FBSDKAppEventsCAPIManager

@objcMembers
public final class FBSDKAppEventsCAPIManager: NSObject, CAPIReporter {
  private static let settingsPath = "cloudbridge_settings"

  public static let shared = FBSDKAppEventsCAPIManager()

  internal var isSDKGKEnabled = false
  internal var factory: GraphRequestFactoryProtocol?
  internal var settings: SettingsProtocol?

  public override init() {}

  public func configure(factory: GraphRequestFactoryProtocol, settings: SettingsProtocol) {
    isSDKGKEnabled = false
    self.factory = factory
    self.settings = settings
  }

  public func enable() {
    isSDKGKEnabled = true
  }

  public func recordEvent(_ parameters: [String: Any]) {
    if isSDKGKEnabled {
      load { isCAPIGEnabled in
        if isCAPIGEnabled {
          FBSDKTransformerGraphRequestFactory.shared.callCapiGatewayAPI(with: parameters)
        }
      }
    }
  }

  private func load(withBlock block: @escaping (Bool) -> Void) {
    guard let appID = settings?.appID else {
      print("App ID is not valid")
      block(false)
      return
    }
    guard let graphRequest = factory?.createGraphRequest(
      withGraphPath: String(format: "%@/%@", appID, FBSDKAppEventsCAPIManager.settingsPath),
      parameters: [:] as [String: Any],
      flags: []
    ) else {
      print("Fail to create CAPI Gateway Settings API request")
      block(false)
      return
    }
    graphRequest.start { _, result, error in
      if let error = error {
        print(error.localizedDescription)
        block(false)
        return
      }

      guard
        let res = result as? [String: Any],
        let data = res["data"] as? [[String: Any]],
        let configuration = data.first
      else {
        print("CAPI Gateway Settings API response is not a valid json")
        block(false)
        return
      }

      guard
        let url = TypeUtility.dictionary(
          configuration,
          objectForKey: SettingsAPIFields.url.rawValue,
          ofType: NSString.self
        ) as? String,
        let datasetID = TypeUtility.dictionary(
          configuration,
          objectForKey: SettingsAPIFields.datasetID.rawValue,
          ofType: NSString.self
        ) as? String,
        let accessKey = TypeUtility.dictionary(
          configuration,
          objectForKey: SettingsAPIFields.accessKey.rawValue,
          ofType: NSString.self
        ) as? String
      else {
        print("CAPI Gateway Settings API response doesn't have valid data")
        block(false)
        return
      }

      FBSDKTransformerGraphRequestFactory.shared.configure(datasetID: datasetID, url: url, accessKey: accessKey)
      let isCAPIGEnabled = TypeUtility.boolValue(
        TypeUtility.dictionary(
          configuration,
          objectForKey: SettingsAPIFields.enabled.rawValue,
          ofType: NSNumber.self
        ) ?? false
      )
      block(isCAPIGEnabled)
    }
  }
}
