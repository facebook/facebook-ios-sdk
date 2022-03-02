/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import FBSDKCoreKit
import FBSDKCoreKit_Basics
import Foundation

/**
 Internal Type exposed to support dependent frameworks.
 API Subject to change or removal without warning. Do not use.

 @warning INTERNAL - DO NOT USE
 */
public enum _ShareUtility {}

extension _ShareUtility: ShareValidating {

  public static func validateRequiredValue(_ value: Any, named name: String) throws {
    let isValid: Bool
    switch value {
    case let string as String:
      isValid = !string.isEmpty
    case let array as [Any]:
      isValid = !array.isEmpty
    case let dictionary as [String: Any]:
      isValid = !dictionary.isEmpty
    default:
      return
    }

    guard isValid else {
      throw ErrorFactory().requiredArgumentError(
        domain: ShareErrorDomain,
        name: name,
        message: nil,
        underlyingError: nil
      )
    }
  }

  public static func validateArgument<Argument>(
    _ value: Argument,
    named name: String,
    in possibleValues: Set<Argument>
  ) throws {
    guard possibleValues.contains(value) else {
      throw ErrorFactory().invalidArgumentError(
        domain: ShareErrorDomain,
        name: name,
        value: value,
        message: nil,
        underlyingError: nil
      )
    }
  }

  static func validateArray(
    _ array: [Any],
    minCount: Int,
    maxCount: Int,
    named name: String
  ) throws {
    guard (minCount ... maxCount).contains(array.count) else {
      throw ErrorFactory().invalidArgumentError(
        domain: ShareErrorDomain,
        name: name,
        value: array,
        message: "\(name) must have \(minCount) to \(maxCount) values",
        underlyingError: nil
      )
    }
  }

  static func validateNetworkURL(_ url: URL, named name: String) throws {
    guard InternalUtility.shared.isBrowserURL(url) else {
      throw ErrorFactory().invalidArgumentError(
        domain: ShareErrorDomain,
        name: name,
        value: url,
        message: nil,
        underlyingError: nil
      )
    }
  }

  static func validateShareContent(
    _ shareContent: SharingContent,
    options bridgeOptions: ShareBridgeOptions = []
  ) throws {
    try validateRequiredValue(shareContent, named: "shareContent")
    try shareContent.validate(options: bridgeOptions)
  }
}

// MARK: - Methods used only by ShareKit

extension _ShareUtility: ShareUtilityProtocol {

  static func buildWebShareBridgeComponents(for content: SharingContent) -> WebShareBridgeComponents {
    var parameters = [String: Any]()

    if let linkContent = content as? ShareLinkContent,
       let url = linkContent.contentURL?.absoluteString {
      parameters["href"] = url
      parameters["quote"] = linkContent.quote
    }

    if !parameters.isEmpty {
      parameters["hashtag"] = hashtagString(from: content.hashtag)
      parameters["place"] = content.placeID
      parameters["tags"] = buildWebShareTags(peopleIDs: content.peopleIDs)
    }

    return WebShareBridgeComponents(
      methodName: ShareBridgeAPI.MethodName.share,
      parameters: parameters
    )
  }

  private static func buildWebShareTags(peopleIDs: [String]) -> String? {
    guard !peopleIDs.isEmpty else { return nil }

    return peopleIDs
      .filter { !$0.isEmpty }
      .joined(separator: ",")
  }

  static func buildAsyncWebPhotoContent(
    _ content: SharePhotoContent,
    completion: @escaping ShareUtilityProtocol.WebPhotoContentHandler
  ) {
    stageImages(for: content) { stagedURIs in
      var parameters = bridgeParameters(
        for: content,
        options: .webHashtag,
        shouldFailOnDataError: false
      )
      parameters.removeValue(forKey: "photos")

      if let json = try? BasicUtility.jsonString(
        for: stagedURIs,
        invalidObjectHandler: nil
      ) {
        parameters["media"] = json
      }

      if let tags = buildWebShareTags(peopleIDs: content.peopleIDs) {
        parameters["tags"] = tags
      }

      completion(true, ShareBridgeAPI.MethodName.share, parameters)
    }
  }

  static func feedShareDictionary(for content: SharingContent) -> [String: Any]? {
    guard let linkContent = content as? ShareLinkContent else { return nil }

    let parameters: [String: Any?] = [
      "link": linkContent.contentURL,
      "quote": linkContent.quote,
      "hashtag": hashtagString(from: linkContent.hashtag),
      "place": content.placeID,
      "tags": buildWebShareTags(peopleIDs: content.peopleIDs),
      "ref": linkContent.ref,
    ]

    return parameters.compactMapValues { $0 }
  }

  static func hashtagString(from hashtag: Hashtag?) -> String? {
    guard let hashtag = hashtag else { return nil }

    guard hashtag.isValid else {
      Logger.singleShotLogEntry(
        .developerErrors,
        logEntry: "Invalid hashtag: '\(hashtag.stringRepresentation)'"
      )

      return nil
    }

    return hashtag.stringRepresentation
  }

  static func bridgeParameters(
    for shareContent: SharingContent,
    options bridgeOptions: ShareBridgeOptions = [],
    shouldFailOnDataError: Bool
  ) -> [String: Any] {
    var nullableParameters: [String: Any?] = [
      "shareUUID": shareContent.shareUUID,
      "tags": shareContent.peopleIDs,
      "place": shareContent.placeID,
      "ref": shareContent.ref,
      "dataFailuresFatal": shouldFailOnDataError,
    ]

    // SharingContent parameters
    if let hashtag = hashtagString(from: shareContent.hashtag),
       !hashtag.isEmpty {
      // When hashtag support was originally added, the Facebook app supported an array of hashtags.
      // This was changed to support a single hashtag; however, the mobile app still expects to receive an array.
      // When hashtag support was added to web dialogs, a single hashtag was passed as a string.
      if bridgeOptions == .webHashtag {
        nullableParameters["hashtag"] = hashtag
      } else {
        nullableParameters["hashtag"] = [hashtag]
      }
    }

    var parameters = nullableParameters.compactMapValues { $0 }

    // Media/destination-specific content parameters
    let updatedParameters = shareContent.addParameters(parameters, options: bridgeOptions)
    parameters.merge(updatedParameters) { $1 }

    return parameters
  }

  static func getContentFlags(for shareContent: SharingContent) -> ContentFlags {
    switch shareContent {
    case is ShareVideoContent:
      return ContentFlags(
        containsMedia: true,
        containsVideos: true
      )
    case let photoContent as SharePhotoContent:
      return getContentFlags(for: photoContent.photos)
    case let mediaContent as ShareMediaContent:
      return getContentFlags(for: mediaContent.media)
    default:
      return ContentFlags()
    }
  }

  static func shareMediaContentContainsPhotosAndVideos(_ shareMediaContent: ShareMediaContent) -> Bool {
    let flags = getContentFlags(for: shareMediaContent)
    return flags.containsVideos && flags.containsPhotos
  }

  private static func stageImages(for photoContent: SharePhotoContent, completion: @escaping ([String]) -> Void) {
    var stagedURIs = [String]()
    let dispatchGroup = DispatchGroup()

    photoContent.photos
      .compactMap(\.image)
      .forEach { image in
        dispatchGroup.enter()

        GraphRequest(
          graphPath: "me/staging_resources",
          parameters: ["file": image],
          httpMethod: .post
        )
          .start { _, result, _ in
            defer { dispatchGroup.leave() }

            guard
              let values = result as? [String: Any],
              let uri = values["uri"] as? String
            else { return }

            stagedURIs.append(uri)
          }
      }

    dispatchGroup.notify(queue: .main) {
      completion(stagedURIs)
    }
  }

  private static func getContentFlags(for object: Any) -> ContentFlags {
    switch object {
    case let photo as SharePhoto:
      return ContentFlags(
        containsMedia: photo.image != nil,
        containsPhotos: true
      )
    case is ShareVideo:
      return ContentFlags(
        containsMedia: true,
        containsVideos: true
      )
    case let items as [Any]:
      var runningFlags = ContentFlags()

      for item in items {
        let flags = getContentFlags(for: item)
        runningFlags |= flags

        if runningFlags.containsAllTypes {
          break
        }
      }

      return runningFlags
    default:
      return ContentFlags()
    }
  }
}
