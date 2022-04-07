/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import FBSDKCoreKit_Basics

@objcMembers
public class FBSDKTransformerGraphRequestFactory: GraphRequestFactory {
  let contentType = "application/json"
  let timeoutInterval = 60
  let maxCachedEvents = 1000
  let maxProcessedEvents = 10

  let retryEventsHttpResponse = [
    -1009, // kCFURLErrorNotConnectedToInternet
    -1004, // kCFURLErrorCannotConnectToHost
    429, // CAPI-G Too many request
    503, // ServiceUnavailable
    504, // GatewayTimeout
  ]

  public static let shared = FBSDKTransformerGraphRequestFactory()

  private let serialQueue: DispatchQueue
  private let factory = GraphRequestFactory()
  internal var credentials: CbCredentials?
  internal var transformedEvents: [[String: Any]] = []

  public struct CbCredentials {
    let accessKey: String
    let capiGatewayURL: String
    let datasetID: String
  }

  public override init() {
    serialQueue = DispatchQueue(label: "com.facebook.appevents.CAPIGateway")
    super.init()
  }

  public func configure(datasetID: String, url: String, accessKey: String) {
    credentials = .init(accessKey: accessKey, capiGatewayURL: url, datasetID: datasetID)
  }

  public func callCapiGatewayAPI(with graphPath: String, parameters: [String: Any]) {
    serialQueue.async { [weak self] in
      guard let self = self,
            let cbEndpoint = self.capiGatewayEndpoint(from: graphPath),
            let url = URL(string: cbEndpoint) else {
        return
      }

      do {
        let transformed = AppEventsConversionsAPITransformer.conversionsAPICompatibleEvent(from: parameters)
        self.appendEvents(events: transformed)
        let count = min(self.transformedEvents.count, self.maxProcessedEvents)
        let processedEvents = Array(self.transformedEvents[0..<count])
        self.transformedEvents.removeSubrange(0..<count)

        let requestDictionary = self.capiGatewayRequestDictionary(with: processedEvents)
        let jsonData = try JSONSerialization.data(withJSONObject: requestDictionary, options: [])

        var request = URLRequest(url: url, cachePolicy: NSURLRequest.CachePolicy.useProtocolCachePolicy, timeoutInterval: TimeInterval(self.timeoutInterval))
        request.httpMethod = HTTPMethod.post.rawValue
        request.setValue(self.contentType, forHTTPHeaderField: "Content-Type")
        request.httpShouldHandleCookies = false
        request.httpBody = jsonData

        URLSession.shared.dataTask(with: request) { _, response, error in
          self.serialQueue.async {
            guard error == nil,
                  let httpResponse = response as? HTTPURLResponse,
                  200...299 ~= httpResponse.statusCode else {
                    self.handleError(response: response, events: processedEvents)
                    return
            }
          }
        }.resume()
      } catch {
        return
      }
    }
  }

  public override func createGraphRequest(withGraphPath graphPath: String, parameters: [String: Any], tokenString: String?, httpMethod: HTTPMethod?, flags: GraphRequestFlags) -> GraphRequestProtocol {
    callCapiGatewayAPI(with: graphPath, parameters: parameters)
    return factory.createGraphRequest(withGraphPath: graphPath, parameters: parameters, tokenString: tokenString, httpMethod: httpMethod, flags: flags)
  }

  public override func createGraphRequest(withGraphPath graphPath: String, parameters: [String: Any]) -> GraphRequestProtocol {
    callCapiGatewayAPI(with: graphPath, parameters: parameters)
    return factory.createGraphRequest(withGraphPath: graphPath, parameters: parameters)
  }

  public override func createGraphRequest(withGraphPath graphPath: String) -> GraphRequestProtocol {
    factory.createGraphRequest(withGraphPath: graphPath)
  }

  public override func createGraphRequest(withGraphPath graphPath: String, parameters: [String: Any], httpMethod: HTTPMethod) -> GraphRequestProtocol {
    callCapiGatewayAPI(with: graphPath, parameters: parameters)
    return factory.createGraphRequest(withGraphPath: graphPath, parameters: parameters, httpMethod: httpMethod)
  }

  public override func createGraphRequest(withGraphPath graphPath: String, parameters: [String: Any], tokenString: String?, version: String?, httpMethod: HTTPMethod) -> GraphRequestProtocol {
    callCapiGatewayAPI(with: graphPath, parameters: parameters)
    return factory.createGraphRequest(withGraphPath: graphPath, parameters: parameters, tokenString: tokenString, version: version, httpMethod: httpMethod)
  }

  public override func createGraphRequest(withGraphPath graphPath: String, parameters: [String: Any], flags: GraphRequestFlags) -> GraphRequestProtocol {
    callCapiGatewayAPI(with: graphPath, parameters: parameters)
    return factory.createGraphRequest(withGraphPath: graphPath, parameters: parameters, flags: flags)
  }

  internal func capiGatewayRequestDictionary(with events: [[String: Any]]) -> [String: Any] {
    guard let accessKey = self.credentials?.accessKey else { return [:] }

    return [
      "data": events,
      "accessKey": accessKey,
    ]
  }

  private func capiGatewayEndpoint(from graphPath: String) -> String? {
    guard let credentials = credentials else { return nil }

    return String(format: "%@/capi/%@/events", credentials.capiGatewayURL, credentials.datasetID)
  }

  internal func handleError(response: URLResponse?, events: [[String: Any]]?) {
    // If it's not server error, we'll re-append the events to the event queue
    let response = response as? HTTPURLResponse
    if let statusCode = response?.statusCode {
      if !self.retryEventsHttpResponse.contains(statusCode) {
        return
      }
    }
    transformedEvents.insert(contentsOf: events ?? [], at: 0)
  }

  internal func appendEvents(events: [[String: Any]]?) {
    transformedEvents.append(contentsOf: events ?? [])
    let remainingEventsCount = transformedEvents.count - maxCachedEvents
    if remainingEventsCount > 0 {
      transformedEvents.removeSubrange(0..<remainingEventsCount)
    }
  }
}
