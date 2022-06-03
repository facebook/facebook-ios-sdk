/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !os(tvOS)

import FBSDKCoreKit_Basics
import Foundation

/**
 Internal Type exposed to facilitate transition to Swift.
 API Subject to change or removal without warning. Do not use.

 @warning INTERNAL - DO NOT USE
 */
@objcMembers
@objc(FBAEMNetworker)
public final class _AEMNetworker: NSObject, AEMNetworking, URLSessionDataDelegate {

  enum Error: Swift.Error {
    case missingOperationQueue
    case failedToCreateURL
    case failedToParseJSON
  }

  private enum Values {
    static let newline = "\r\n"
    static let versionString = "14.0.0"
    static let defaultGraphAPIVersion = "v14.0"
    static let SDK = "ios"
    static let userAgentBase = "FBiOSAEM"
    static let graphAPIEndpoint = "https://graph.facebook.com/v14.0/"
    static let graphAPIContentType = "application/json"
    static let errorDomain = "com.facebook.aemkit"
    static let agent = "\(Values.userAgentBase).\(Values.versionString)"
  }

  public var userAgentSuffix: String?

  lazy var userAgent: String = {
    var agentWithSuffix = Values.agent
    if let userAgentSuffix = userAgentSuffix, !userAgentSuffix.isEmpty {
      agentWithSuffix += "/\(userAgentSuffix)"
    }

    if #available(iOS 13.0, *),
       ProcessInfo.processInfo.isMacCatalystApp {
      return agentWithSuffix + "/macOS"
    }

    return agentWithSuffix
  }()

  // MARK: - AEMNetworking

  public func startGraphRequest(
    withGraphPath graphPath: String,
    parameters: [String: Any],
    tokenString: String?,
    httpMethod method: String?,
    completion: @escaping FBGraphRequestCompletion
  ) {
    guard let url = URL(string: Values.graphAPIEndpoint + graphPath) else {
      completion(nil, Error.failedToCreateURL)
      return
    }

    var request = URLRequest(url: url, cachePolicy: .useProtocolCachePolicy, timeoutInterval: 60.0)
    request.httpMethod = method
    request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
    request.setValue(Values.graphAPIContentType, forHTTPHeaderField: "Content-Type")
    request.httpShouldHandleCookies = false

    // add parameters to body
    let body = _AEMRequestBody()

    var params = parameters
    params["format"] = "json"
    params["sdk"] = Values.SDK
    params["include_headers"] = "false"

    appendAttachments(attachments: params, toBody: body, addFormData: method == "POST")

    if request.httpMethod == "POST" {
      request.httpBody = body.compressedData()
      request.setValue("gzip", forHTTPHeaderField: "Content-Encoding")
    } else {
      request.httpBody = body.data
    }

    guard let queue = OperationQueue.current else {
      completion(nil, Error.missingOperationQueue)
      return
    }

    let session = FBSDKURLSession(delegate: self, delegateQueue: queue)
    session.execute(request) { [weak self] responseData, response, error in
      guard let httpResponse = response as? HTTPURLResponse else {
        completion(nil, URLError(.badServerResponse))
        return
      }

      if let error = error {
        completion(nil, error)
        return
      }

      var parseError: Swift.Error?
      let result = self?.parseJSONResponse(
        data: responseData,
        error: &parseError,
        statusCode: httpResponse.statusCode
      )

      if let error = parseError {
        completion(nil, error)
        return
      }

      guard let result = result else {
        completion(nil, Error.failedToParseJSON)
        return
      }

      completion(result, error)
    }
  }

  func parseJSONResponse(
    data: Data?,
    error: inout Swift.Error?,
    statusCode: Int
  ) -> [String: Any] {
    guard let data = data else {
      return [:]
    }

    let rawResponse = String(data: data, encoding: .utf8)
    let response = parseJSONOrOtherwise(unsafeString: rawResponse, error: &error)
    var result = [String: Any]()

    if rawResponse == nil {
      let base64Data = !data.isEmpty ? data.base64EncodedString(options: .lineLength64Characters) : ""
      if !base64Data.isEmpty {
        print("fb_response_invalid_utf8")
      }
    }

    if response == nil,
       error == nil {
      error = NSError(domain: Values.errorDomain, code: statusCode, userInfo: nil)
    } else if error != nil, response != nil {
      return [:]
    } else if let response = response as? [String: Any] {
      result = response
    }

    return result
  }

  func parseJSONOrOtherwise(
    unsafeString: String?,
    error: inout Swift.Error?
  ) -> Any? {
    var parsed: Any?
    if let utf8 = unsafeString, error == nil {
      guard let data = utf8.data(using: .utf8) else {
        return nil
      }
      do {
        parsed = try JSONSerialization.jsonObject(with: data, options: [])
        // swiftlint:disable:next untyped_error_in_catch
      } catch let serializationError {
        error = serializationError
        return nil
      }
    }
    return parsed
  }

  func appendAttachments(
    attachments: [String: Any],
    toBody body: _AEMRequestBody,
    addFormData: Bool
  ) {
    for (key, value) in attachments {
      var typedvalue: String?
      if let integer = value as? Int {
        typedvalue = "\(integer)"
      } else if let number = value as? NSNumber {
        typedvalue = number.stringValue
      } else if let url = value as? URL {
        typedvalue = url.absoluteString
      }

      if let string = typedvalue,
         addFormData {
        body.append(withKey: key, formValue: string)
      } else {
        print("Unsupported attachment:\(String(describing: value)), skipping.")
      }
    }
  }
}

#endif
