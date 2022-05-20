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

@objcMembers
public final class FBSDKAppEventsCAPIManager: NSObject, CAPIReporter {
  private static let settingsPath = "cloudbridge_settings"

  public static let shared = FBSDKAppEventsCAPIManager()

  internal var isEnabled: Bool = false
  internal var factory: GraphRequestFactoryProtocol?
  internal var settings: SettingsProtocol?

  public override init() {}

  public func configure(factory: GraphRequestFactoryProtocol, settings: SettingsProtocol) {
    isEnabled = false
    self.factory = factory
    self.settings = settings
  }

  public func enable() {
    guard let appID = settings?.appID else {
      print("App ID is not valid"); return
    }
    guard let graphRequest = factory?.createGraphRequest(
      withGraphPath: String(format: "%@/%@", appID, FBSDKAppEventsCAPIManager.settingsPath),
      parameters: [:] as [String: Any],
      flags: []
    ) else {
      print("Fail to create CAPI Gateway Settings API request"); return
    }
    graphRequest.start { _, result, error in
      if let error = error {
        print(error.localizedDescription)
        return
      }

      guard
        let res = result as? [String: Any],
        let data = res["data"] as? [[String: Any]],
        let configuration = data.first
      else {
        print("CAPI Gateway Settings API response is not a valid json")
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
        return
      }

      FBSDKTransformerGraphRequestFactory.shared.configure(datasetID: datasetID, url: url, accessKey: accessKey)
      self.isEnabled = TypeUtility.boolValue(
        TypeUtility.dictionary(
          configuration,
          objectForKey: SettingsAPIFields.enabled.rawValue,
          ofType: NSNumber.self
        ) ?? false
      )
    }
  }

  public func recordEvent(_ parameters: [String: Any]) {
    if isEnabled {
      FBSDKTransformerGraphRequestFactory.shared.callCapiGatewayAPI(with: parameters)
    }
  }
}
