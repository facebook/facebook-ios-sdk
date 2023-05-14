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
public typealias CAPIGBlock = (Bool) -> Void

@objcMembers
public final class FBSDKAppEventsCAPIManager: NSObject, CAPIReporter {
  private static let settingsPath = "cloudbridge_settings"
  private static let serialQueue = DispatchQueue(label: "capi_gateway_queue")

  public static let shared = FBSDKAppEventsCAPIManager()

  internal var isSDKGKEnabled = false
  internal var factory: GraphRequestFactoryProtocol?
  internal var settings: SettingsProtocol?
  internal var configRefreshTimestamp: Date?
  internal var isLoadingConfig = false
  internal var completionBlocks: [CAPIGBlock] = []

  private enum TimeIntervals {
    static let configTimeout: TimeInterval = 86400
  }

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
          FBSDKTransformerGraphRequestFactory.shared.callCapiGatewayAPI(
            with: parameters,
            userAgent: "FBiOSSDK.\(self.settings?.sdkVersion ?? "Unknown")"
          )
        }
      }
    }
  }

  internal func load(withBlock block: @escaping (Bool) -> Void) {
    guard let appID = settings?.appID else {
      print("App ID is not valid")
      block(false)
      return
    }

    FBSDKAppEventsCAPIManager.dispatchOnQueue(FBSDKAppEventsCAPIManager.serialQueue) {
      self.completionBlocks.append(block)

      if !self.shouldRefresh() {
        self.executeBlocks(isEnabled: true)
        return
      }

      if self.isLoadingConfig {
        return
      }

      self.isLoadingConfig = true
      guard let graphRequest = self.factory?.createGraphRequest(
        withGraphPath: String(format: "%@/%@", appID, FBSDKAppEventsCAPIManager.settingsPath),
        parameters: [:] as [String: Any],
        flags: []
      ) else {
        print("Fail to create CAPI Gateway Settings API request")
        self.executeBlocks(isEnabled: false)
        self.isLoadingConfig = false
        return
      }
      graphRequest.start { _, result, error in
        FBSDKAppEventsCAPIManager.dispatchOnQueue(FBSDKAppEventsCAPIManager.serialQueue) {
          if let error = error {
            print(error.localizedDescription)
            self.executeBlocks(isEnabled: false)
            self.isLoadingConfig = false
            return
          }

          guard
            let res = result as? [String: Any],
            let data = res["data"] as? [[String: Any]],
            let configuration = data.first
          else {
            print("CAPI Gateway Settings API response is not a valid json")
            self.executeBlocks(isEnabled: false)
            self.isLoadingConfig = false
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
            self.executeBlocks(isEnabled: false)
            self.isLoadingConfig = false
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
          self.executeBlocks(isEnabled: isCAPIGEnabled)
          self.isLoadingConfig = false
        }
      }
    }
  }

  func shouldRefresh() -> Bool {
    // We should refresh the config if
    // 1. refresh timestamp is expired
    // 2. local config doesn't exist
    return !isRefreshTimestampValid() ||
      FBSDKTransformerGraphRequestFactory.shared.credentials == nil
  }

  func isRefreshTimestampValid() -> Bool {
    guard let timestamp = configRefreshTimestamp else {
      return false
    }
    return Date().timeIntervalSince(timestamp) < TimeIntervals.configTimeout
  }

  func executeBlocks(isEnabled: Bool) {
    for block in completionBlocks {
      block(isEnabled)
    }
    completionBlocks = []
  }

  private static func dispatchOnQueue(
    _ queue: DispatchQueue,
    block: @escaping (() -> Void)
  ) {
    #if DEBUG
    block()
    #else
    queue.async(execute: block)
    #endif
  }
}
