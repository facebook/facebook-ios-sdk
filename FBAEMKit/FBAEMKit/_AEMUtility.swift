/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import FBSDKCoreKit_Basics
import Foundation

#if !os(tvOS)

@objcMembers
@objc(FBAEMUtility)
public final class _AEMUtility: NSObject {
  private enum Keys {
    static let content = "fb_content"
    static let contentID = "fb_content_id"
    static let itemPrice = "item_price"
    static let identity = "id"
    static let quantity = "quantity"
  }

  @objc(sharedUtility) public static let shared = _AEMUtility()

  public func getInSegmentValue(
    _ parameters: [String: Any]?,
    matchingRule: _AEMAdvertiserRuleMatching?
  ) -> NSNumber {
    guard let parameters = parameters,
          let contentsData = parameters[Keys.content] as? [[String: Any]] else {
      return 0
    }

    let value = contentsData.reduce(0.0) { value, entry in
      if let matchingRule = matchingRule,
         matchingRule.isMatchedEventParameters([Keys.content: [entry]]) {
        let itemPrice = entry[Keys.itemPrice] as? NSNumber ?? 0
        let quantity = entry[Keys.quantity] as? NSNumber ?? 1

        return value + itemPrice.doubleValue * quantity.doubleValue
      } else {
        return value
      }
    }

    return NSNumber(value: value)
  }

  public func getContentID(_ parameters: [String: Any]?) -> String? {
    guard let parameters = parameters else {
      return nil
    }

    let content = parameters[Keys.content] as? String

    return content.flatMap { content in
      do {
        return try getContentIDs(content)
      } catch {
        NSLog("Fail to parse AEM fb_content")
        return nil
      }
    } ?? (parameters[Keys.contentID] as? String)
  }

  private func getContentIDs(_ content: String) throws -> String {
    guard let json = try TypeUtility.jsonObject(
      with: Data(content.utf8),
      options: .mutableContainers
    ) as? [[String: Any]] else {
      throw Error.invalidContentIDsJSONObject
    }

    let contentIDs = json.reduce(into: [String]()) { result, entry in
      if let contentID = entry[Keys.identity] as? NSNumber {
        result.append(contentID.stringValue)
      } else if let contentID = entry[Keys.identity] as? String {
        result.append(contentID)
      }
    }

    return try BasicUtility.jsonString(for: contentIDs, invalidObjectHandler: nil)
  }

  private enum Error: Swift.Error {
    case invalidContentIDsJSONObject
  }
}

#endif
