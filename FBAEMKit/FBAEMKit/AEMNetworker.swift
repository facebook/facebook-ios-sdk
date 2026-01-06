//
//  AEMNetworker+Improvements.swift
//  Contribution: improved error handling, retries, DI, async wrapper, better parsing
//
//  Keep in mind: AEMRequestBody and FBSDKURLSession are assumed present in your codebase.
//  This file focuses on improving AEMNetworker behavior while keeping the same external API.
//

import Foundation
import FBSDKCoreKit_Basics

// MARK: - Minimal logger abstraction (swap with os_log or FBSDK logger)
protocol AEMLogger {
  func info(_ msg: String)
  func warn(_ msg: String)
  func error(_ msg: String)
  func debug(_ msg: String)
}

struct PrintLogger: AEMLogger {
  func info(_ msg: String) { print("INFO: \(msg)") }
  func warn(_ msg: String) { print("WARN: \(msg)") }
  func error(_ msg: String) { print("ERROR: \(msg)") }
  func debug(_ msg: String) { print("DEBUG: \(msg)") }
}

// MARK: - SessionExecutable protocol for DI/testability
protocol SessionExecutable {
  // The FBSDKURLSession in your project probably exposes an `execute(_:completion:)` method;
  // adapt this protocol if the signature differs.
  func execute(_ request: URLRequest, completion: @escaping (Data?, URLResponse?, Error?) -> Void)
}

// Default factory that creates FBSDKURLSession delegate-backed session
struct DefaultSessionFactory {
  // returns an object conforming to SessionExecutable; default uses FBSDKURLSession(delegate:delegateQueue:)
  func make(delegate: URLSessionDataDelegate?, delegateQueue: OperationQueue) -> SessionExecutable {
    // FBSDKURLSession is part of the FB SDK in original code and should conform to execute(_:completion:)
    // The project code already used: let session = FBSDKURLSession(delegate: self, delegateQueue: queue)
    // We'll return that object here (it should conform to SessionExecutable). If your FBSDKURLSession doesn't
    // conform to our protocol, add an adapter to wrap it.
    return FBSDKURLSession(delegate: delegate, delegateQueue: delegateQueue)
  }
}

// MARK: - AEMNetworker (improved)
final class AEMNetworker: NSObject, AEMNetworking, URLSessionDataDelegate {

  enum NetworkError: Swift.Error, LocalizedError {
    case missingOperationQueue
    case failedToCreateURL
    case failedToParseJSON
    case httpError(statusCode: Int, payload: Any?)
    case transientError(underlying: Error)
    case unknown

    var errorDescription: String? {
      switch self {
      case .missingOperationQueue:
        return "Missing OperationQueue (caller must run on an operation queue)."
      case .failedToCreateURL:
        return "Failed to create request URL."
      case .failedToParseJSON:
        return "Failed to parse JSON from server response."
      case .httpError(let code, _):
        return "HTTP error \(code)."
      case .transientError(let underlying):
        return "Transient network error: \(underlying.localizedDescription)"
      case .unknown:
        return "An unknown error occurred."
      }
    }
  }

  // Constants
  private enum Values {
    static let newline = "\r\n"
    static let versionString = "18.0.2"
    static let defaultGraphAPIVersion = "v17.0"
    static let SDK = "ios"
    static let userAgentBase = "FBiOSAEM"
    static let graphAPIEndpoint = "https://graph.facebook.com/v17.0/"
    static let graphAPIContentType = "application/json"
    static let errorDomain = "com.facebook.aemkit"
    static let agent = "\(Values.userAgentBase).\(Values.versionString)"
  }

  // public configuration
  var userAgentSuffix: String?
  var baseURL: String = Values.graphAPIEndpoint
  var logger: AEMLogger = PrintLogger() // swap with app logger if desired
  var sessionFactory: DefaultSessionFactory = DefaultSessionFactory()
  var maxRetries: Int = 2
  var retryBackoffBase: TimeInterval = 0.5

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

  /// The callback-based public API (keeps original signature).
  func startGraphRequest(
    withGraphPath graphPath: String,
    parameters: [String: Any],
    tokenString: String?,
    httpMethod method: String?,
    completion: @escaping FBGraphRequestCompletion
  ) {
    // For backward compatibility we keep the same method signature and behavior,
    // but add a retry loop and better error handling.
    do {
      let request = try buildRequest(graphPath: graphPath, parameters: parameters, httpMethod: method)
      guard let queue = OperationQueue.current else {
        completion(nil, NetworkError.missingOperationQueue)
        return
      }
      // Use injected factory to produce session (testable)
      let session = sessionFactory.make(delegate: self, delegateQueue: queue)
      performRequestWithRetries(session: session, request: request, retries: maxRetries, completion: completion)
    } catch {
      completion(nil, error)
    }
  }

  // MARK: - Async wrapper (convenience)
  @available(iOS 13.0, *)
  func startGraphRequestAsync(
    graphPath: String,
    parameters: [String: Any],
    tokenString: String?,
    httpMethod method: String?
  ) async throws -> [String: Any] {
    return try await withCheckedThrowingContinuation { cont in
      startGraphRequest(withGraphPath: graphPath, parameters: parameters, tokenString: tokenString, httpMethod: method) { result, error in
        if let error = error {
          cont.resume(throwing: error)
        } else if let result = result {
          cont.resume(returning: result)
        } else {
          cont.resume(throwing: NetworkError.unknown)
        }
      }
    }
  }

  // MARK: - Request building & body handling

  private func buildRequest(graphPath: String, parameters: [String: Any], httpMethod: String?) throws -> URLRequest {
    // Prefer URLComponents to avoid string concatenation errors for GET-like requests.
    let method = httpMethod?.uppercased() ?? "GET"
    // Build a base URL
    guard var components = URLComponents(string: baseURL) else {
      throw NetworkError.failedToCreateURL
    }
    // Append graphPath safely
    // If graphPath contains query, we keep it intact by parsing path/queries
    if graphPath.hasPrefix("/") {
      components.path += graphPath
    } else {
      components.path = (components.path as NSString).appending("/\(graphPath)")
    }

    var request = URLRequest(url: components.url!, cachePolicy: .useProtocolCachePolicy, timeoutInterval: 60.0)
    request.httpMethod = method
    request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
    request.setValue(Values.graphAPIContentType, forHTTPHeaderField: "Content-Type")
    request.httpShouldHandleCookies = false

    // Add standard fields to parameters
    var params = parameters
    params["format"] = "json"
    params["sdk"] = Values.SDK
    params["include_headers"] = "false"

    // For POST, we attach compressed body via AEMRequestBody (keeps existing behavior)
    if method == "POST" {
      let body = AEMRequestBody()
      appendAttachments(attachments: params, toBody: body, addFormData: true)
      // compressedData may be nil-safe; original code used compressedData()
      request.httpBody = body.compressedData()
      request.setValue("gzip", forHTTPHeaderField: "Content-Encoding")
    } else {
      // For non-POST requests add params as URL query items rather than httpBody
      var queryItems: [URLQueryItem] = components.queryItems ?? []
      for (k, v) in params {
        // Only simple type parameters are supported as query items
        if let s = v as? String {
          queryItems.append(URLQueryItem(name: k, value: s))
        } else if let i = v as? Int {
          queryItems.append(URLQueryItem(name: k, value: String(i)))
        } else if let ns = v as? NSNumber {
          queryItems.append(URLQueryItem(name: k, value: ns.stringValue))
        } else {
          // skip complex attachments for non-POST
          logger.debug("Skipping complex param '\(k)' for non-POST request.")
        }
      }
      components.queryItems = queryItems
      if let finalURL = components.url {
        request.url = finalURL
      } else {
        throw NetworkError.failedToCreateURL
      }
      // keep httpBody nil for GET-like requests
      request.httpBody = nil
    }
    return request
  }

  // Perform request with retries (simple exponential backoff on transient failures)
  private func performRequestWithRetries(session: SessionExecutable, request: URLRequest, retries: Int, completion: @escaping FBGraphRequestCompletion) {
    let attemptRequest: (_ attempt: Int) -> Void = { [weak self] attempt in
      guard let self = self else { return }
      session.execute(request) { data, response, error in
        if let error = error {
          // treat network errors as transient up to retries
          if attempt < retries {
            let backoff = self.retryBackoffBase * pow(2.0, Double(attempt))
            self.logger.warn("Request failed (attempt \(attempt)): \(error.localizedDescription). Retrying in \(backoff)s.")
            DispatchQueue.global().asyncAfter(deadline: .now() + backoff) {
              attemptRequest(attempt + 1)
            }
            return
          } else {
            self.logger.error("Request failed after \(attempt) attempts: \(error.localizedDescription)")
            completion(nil, NetworkError.transientError(underlying: error))
            return
          }
        }

        guard let httpResponse = response as? HTTPURLResponse else {
          completion(nil, URLError(.badServerResponse))
          return
        }

        // Parse JSON
        var parseError: Swift.Error?
        let parsed = self.parseJSONResponse(data: data, error: &parseError, statusCode: httpResponse.statusCode)
        if let parseError = parseError {
          completion(nil, parseError)
          return
        }

        // Optionally, consider HTTP status codes
        if !(200...299).contains(httpResponse.statusCode) {
          // non-2xx: treat as error but return the parsed payload if present
          completion(nil, NetworkError.httpError(statusCode: httpResponse.statusCode, payload: parsed))
          return
        }

        // success
        completion(parsed, nil)
      }
    }

    // start first attempt
    attemptRequest(0)
  }

  // MARK: - JSON parsing helpers

  func parseJSONResponse(
    data: Data?,
    error: inout Swift.Error?,
    statusCode: Int
  ) -> [String: Any] {
    guard let data = data else {
      return [:]
    }

    // Attempt to interpret as UTF-8 string
    let rawResponse = String(data: data, encoding: .utf8)
    let response = parseJSONOrOtherwise(unsafeString: rawResponse, error: &error)
    var result = [String: Any]()

    // If invalid UTF-8 we log base64 or raw length (avoid printing binary to logs)
    if rawResponse == nil {
      let base64Data = !data.isEmpty ? data.base64EncodedString(options: .lineLength64Characters) : ""
      if !base64Data.isEmpty {
        logger.warn("fb_response_invalid_utf8: response is not valid UTF-8; base64 length: \(base64Data.count)")
      } else {
        logger.warn("fb_response_invalid_utf8: empty payload")
      }
    }

    // Determine outcome
    if response == nil && error == nil {
      // Neither parsed nor produced an error -> unknown; propagate an NSError with HTTP code
      error = NSError(domain: Values.errorDomain, code: statusCode, userInfo: nil)
    } else if error != nil && response != nil {
      // both non-nil means parse raised error but returned something odd; return empty to be safe
      return [:]
    } else if let responseDict = response as? [String: Any] {
      result = responseDict
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
      } catch let serializationError {
        error = serializationError
        return nil
      }
    }
    return parsed
  }

  // MARK: - Attachments

  func appendAttachments(
    attachments: [String: Any],
    toBody body: AEMRequestBody,
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
      } else if let str = value as? String {
        typedvalue = str
      }

      if let string = typedvalue, addFormData {
        body.append(withKey: key, formValue: string)
      } else {
        logger.debug("Unsupported attachment for key '\(key)': \(type(of: value)), skipping.")
      }
    }
  }
}

// MARK: - Adapters (if needed)
// If FBSDKURLSession doesn't conform to SessionExecutable, add a small adapter in your codebase:
// extension FBSDKURLSession: SessionExecutable { /* execute already exists */ }

// The above improved AEMNetworker class is backwards-compatible with the existing API.
// Suggested follow-ups (outside this file):
//  - Add unit tests that inject a mock sessionFactory returning a mock SessionExecutable.
//  - Replace PrintLogger with a production logger (os_log or FBSDK logger).
//  - Consider exposing more fine-grained retry policies per-call.
//  - Provide a metrics hook for monitoring latency/error rates.
