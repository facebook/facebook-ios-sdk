/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import FBSDKCoreKit
import Foundation

struct ServerResult: Codable {
  var success: Bool
}

/**
 Errors representing a failure to send a custom update graph request
 */
public enum CustomUpdateGraphRequestError: Error {
  case server(Error)
  case invalidAccessToken
  case contentParsing
  case decoding
}

public class CustomUpdateGraphRequest {

  public let graphRequestFactory: GraphRequestFactoryProtocol
  let graphPath = "me/custom_update"
  let gamingGraphDomain = "gaming"
  let base64EncodedImageHeader = "data:image/png;base64,"

  public init() {
    graphRequestFactory = GraphRequestFactory()
  }

  public init(graphRequestFactory: GraphRequestFactoryProtocol = GraphRequestFactory()) {
    self.graphRequestFactory = graphRequestFactory
  }

  /**
    This will attempt to send a custom update graph request with the given content

   - Parameters:
    - content: A media custom update request content
    - completionHandler:  A completion handler to be invoked with the graph request success result or error
   */
  public func request(
    content: CustomUpdateContentMedia,
    completionHandler: @escaping (Result<Bool, CustomUpdateGraphRequestError>) -> Void
  ) throws {
    guard let authToken = AuthenticationToken.current, authToken.graphDomain == gamingGraphDomain else {
      throw CustomUpdateGraphRequestError.invalidAccessToken
    }

    let remoteContent = try CustomUpdateGraphAPIContentRemote(customUpdateContentMedia: content)
    let parameters = try parameterDictionary(content: remoteContent)
    let request = graphRequestFactory.createGraphRequest(
      withGraphPath: graphPath,
      parameters: parameters,
      httpMethod: HTTPMethod.post
    )

    try start(request: request, completion: completionHandler)
  }

  /**
    This will attempt to send a custom update graph request with the given content

   - Parameters:
    - content: An image custom update request content
    - completionHandler:  A completion handler to be invoked if  with the graph request success result or error
   */
  public func request(
    content: CustomUpdateContentImage,
    completionHandler: @escaping (Result<Bool, CustomUpdateGraphRequestError>) -> Void
  ) throws {
    guard let authToken = AuthenticationToken.current, authToken.graphDomain == gamingGraphDomain else {
      throw CustomUpdateGraphRequestError.invalidAccessToken
    }

    let remoteContent = try CustomUpdateGraphAPIContentRemote(customUpdateContentImage: content)
    let parameters = try parameterDictionary(content: remoteContent)
    let request = graphRequestFactory.createGraphRequest(
      withGraphPath: graphPath,
      parameters: parameters,
      httpMethod: HTTPMethod.post
    )

    try start(request: request, completion: completionHandler)
  }

  private func start(
    request: GraphRequestProtocol,
    completion: @escaping (Result<Bool, CustomUpdateGraphRequestError>) -> Void
  )
  throws {
    request.start { _, result, error in
      if let error = error {
        return completion(.failure(.server(error)))
      }
      guard
        let result = result as? [String: Bool],
        let data = try? JSONSerialization.data(withJSONObject: result, options: []),
        let serverResult = try? JSONDecoder().decode(ServerResult.self, from: data)
      else {
        return completion(.failure(.decoding))
      }
      completion(.success(serverResult.success))
    }
  }

  private func parameterDictionary(content: CustomUpdateGraphAPIContentRemote) throws -> [String: Any] {
    let encodedContent = try JSONEncoder().encode(content)
    guard var parameters = try JSONSerialization.jsonObject(
      with: encodedContent,
      options: .allowFragments
    ) as? [String: Any] else {
      throw ErrorFactory().invalidArgumentError(
        name: "CustomUpdateContent",
        value: content,
        message: "Custom Update Content is invalid please check parameters.",
        underlyingError: nil
      )
    }

    parameters["text"] = try NSString(
      data: JSONEncoder().encode(content.text),
      encoding: String.Encoding.utf8.rawValue
    )

    if let cta = content.cta {
      parameters["cta"] = try NSString(
        data: JSONEncoder().encode(cta),
        encoding: String.Encoding.utf8.rawValue
      )
    }

    if let media = content.media {
      parameters["media"] = try NSString(
        data: JSONEncoder().encode(media),
        encoding: String.Encoding.utf8.rawValue
      )
    }

    if let imageData = content.image {
      parameters["image"] = base64EncodedImageHeader + imageData.base64EncodedString()
    }

    return parameters
  }
}
