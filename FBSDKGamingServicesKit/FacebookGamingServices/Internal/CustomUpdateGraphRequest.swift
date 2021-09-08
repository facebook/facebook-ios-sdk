// Copyright (c) 2014-present, Facebook, Inc. All rights reserved.
//
// You are hereby granted a non-exclusive, worldwide, royalty-free license to use,
// copy, modify, and distribute this software in source code or binary form for use
// in connection with the web services and APIs provided by Facebook.
//
// As with any software that integrates with the Facebook platform, your use of
// this software is subject to the Facebook Developer Principles and Policies
// [http://developers.facebook.com/policy/]. This copyright notice shall be
// included in all copies or substantial portions of the software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
// FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
// COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
// IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
// CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

#if FBSDK_SWIFT_PACKAGE
import FacebookCore
#else
import FBSDKCoreKit
#endif
import Foundation

struct ServerResult: Codable {
  var success: Bool
}

/**
 Errors representing a failure to send a custom update graph request
 */
public enum CustomUpdateGraphRequestError: Error {
  case server(Error)
  case contentParsing
  case decoding
}

public class CustomUpdateGraphRequest {

  public let graphRequestFactory: GraphRequestProviding
  let graphPath = "me/custom_update"
  let base64EncodedImageHeader = "data:image/png;base64,"

  public init() {
    self.graphRequestFactory = GraphRequestFactory()
  }

  public init(graphRequestFactory: GraphRequestProviding = GraphRequestFactory()) {
    self.graphRequestFactory = graphRequestFactory
  }

  /**
    This will attempt to send a custom update graph request with the given content

   - Parameters:
    - content: A media custom update request content
    - completionHandler:  A completion handler to be invoked if an
   */
  public func request(
    content: CustomUpdateContentMedia,
    completionHandler: @escaping (Result<Bool, CustomUpdateGraphRequestError>) -> Void
  )
  throws {
    guard let remoteContent = CustomUpdateGraphAPIContentRemote(customUpdateContentMedia: content) else {
      return completionHandler(.failure(.contentParsing))
    }

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
    - completionHandler:  A completion handler to be invoked if an
   */
  public func request(
    content: CustomUpdateContentImage,
    completionHandler: @escaping (Result<Bool, CustomUpdateGraphRequestError>) -> Void
  )
  throws {
    guard let remoteContent = CustomUpdateGraphAPIContentRemote(customUpdateContentImage: content) else {
      return completionHandler(.failure(.contentParsing))
    }
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
      throw SDKError.invalidArgumentError(
        withName: "CustomUpdateContent",
        value: content,
        message: "Custom Update Content is invalid please check parameters."
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
