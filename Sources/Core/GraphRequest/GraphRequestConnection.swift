// Copyright (c) 2016-present, Facebook, Inc. All rights reserved.
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

import FBSDKCoreKit.FBSDKGraphRequestConnection
import Foundation

//--------------------------------------
// MARK: - GraphRequestConnection
//--------------------------------------
/**
 Represents a single connection to Facebook to service a single or multiple requests.

 The request settings and properties are encapsulated in a reusable `GraphRequest` or a custom `GraphRequestProtocol`.
 This object encapsulates the concerns of a single communication
 e.g. starting a connection, canceling a connection, or batching requests.
 */
public class GraphRequestConnection {
  /// A type of the closure that could be used to track network progress of a specific connection.
  public typealias NetworkProgressHandler =
    (_ bytesSent: Int64, _ totalBytesSent: Int64, _ totalExpectedBytes: Int64) -> Void

  /// A type of the closure that could be used to track network errors of a specific connection.
  public typealias NetworkFailureHandler = (Error) -> Void

  /// Network progress closure that is going to be called every time data is sent to the server.
  public var networkProgressHandler: NetworkProgressHandler? = nil {
    didSet {
      sdkDelegateBridge.networkProgressHandler = networkProgressHandler
    }
  }

  /**
   Network failure handler that is going to be called when a connection fails with a network error.
   Use completion on per request basis to get additional information, that is not related to network errors.
   */
  public var networkFailureHandler: NetworkFailureHandler? = nil {
    didSet {
      sdkDelegateBridge.networkFailureHandler = networkFailureHandler
    }
  }

  /// The operation queue that is used to call all network handlers.
  public var networkHandlerQueue: OperationQueue = OperationQueue.main {
    didSet {
      sdkConnection.setDelegateQueue(networkHandlerQueue)
    }
  }

  private var sdkConnection: FBSDKGraphRequestConnection = FBSDKGraphRequestConnection()
  private var sdkDelegateBridge: GraphRequestConnectionDelegateBridge = GraphRequestConnectionDelegateBridge()

  /**
   Initializes a connection.
   */
  public init() {
    sdkDelegateBridge.setupAsDelegateFor(sdkConnection)
  }

  //--------------------------------------
  // MARK: - Requests
  //--------------------------------------

  public typealias Completion<T: GraphRequestProtocol> =
    (_ httpResponse: HTTPURLResponse?, _ result: GraphRequestResult<T>) -> Void

  /**
   Adds a request object to this connection.

   - parameter request: Request to be included in this connection.
   - parameter batchEntryName: Optional name for this request.
   This can be used to feed the results of one request to the input of another,
   as long as they are in the same `GraphRequestConnection`
   As described in [Graph API Batch Requests](https://developers.facebook.com/docs/reference/api/batch/).
   - parameter completion: Optional completion closure that is going to be called when the connection finishes or fails.
   */
  public func add<T>(_ request: T,
                     batchEntryName: String? = nil,
                     completion: Completion<T>? = nil) {
    let batchParameters = batchEntryName.map { ["name": $0] }
    add(request, batchParameters: batchParameters as [String: Any]?, completion: completion)
  }

  /**
   Adds a request object to this connection.

   - parameter request: Request to be included in this connection.
   - parameter batchParameters: Optional dictionary of parameters to include for this request
   as described in [Graph API Batch Requests](https://developers.facebook.com/docs/reference/api/batch/).
   Examples include "depends_on", "name", or "omit_response_on_success".
   - parameter completion: Optional completion closure that is going to be called when the connection finishes or fails.
   */
  public func add<T>(_ request: T,
                     batchParameters: [String: Any]?,
                     completion: Completion<T>? = nil) {
    sdkConnection.add(request.sdkRequest,
                      completionHandler: completion.map(type(of: self).sdkRequestCompletion),
                      batchParameters: batchParameters)
  }

  /**
   Starts a connection with the server and sends all the requests in this connection.
   - warning: This method can't be called twice per a single `GraphRequestConnection` instance.
   */
  public func start() {
    sdkConnection.start()
  }

  /**
   Signals that a connect should be logically terminated as per application is no longer interested in a response.

   Synchronouslly calls any handlers indicating the request was cancelled.
   This doesn't guarantee that the request-related processing will cease.
   It does promise that all handlers will complete before the cancel returns.
   A call to `cancel` prior to a start implies a cancellation of all requests associated with the connection.
   */
  public func cancel() {
    sdkConnection.cancel()
  }

  //--------------------------------------
  // MARK: - Private
  //--------------------------------------

  /// Custom typealias that is the same as FBSDKGraphRequestHandler, but without implicitly unwrapped optionals.
  internal typealias SDKRequestCompletion =
    (_ connection: FBSDKGraphRequestConnection?, _ rawResponse: Any?, _ error: Error?) -> Void

  internal static func sdkRequestCompletion<T>(from completion: @escaping Completion<T>) -> SDKRequestCompletion {
    return { connection, rawResponse, error in
      let result: GraphRequestResult<T> = {
        switch error {
        case let error?:
          return .failed(error)
        default:
          return .success(response: T.Response(rawResponse: rawResponse))
        }
      }()
      completion(connection?.urlResponse, result)
    }
  }
}
