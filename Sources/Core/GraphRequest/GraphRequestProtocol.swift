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

import Foundation

import FBSDKCoreKit

/**
 Protocol that represents a request to the Facebook Graph API.

 An implementation of this protocol is intended to be either generic and be used for a lot of separate endpoints,
 or encapsulate a request + response type for a single endpoint, for example `Profile`.

 To send a request and receive a response - see `GraphRequestConnection`.

 Nearly all Graph APIs require an access token.
 Unless specified, the `AccessToken.current` is used. Therefore, most requests
 will require login first (see `LoginManager` in `FacebookLogin.framework`).

 A `start` function is provided for convenience for single requests.
 */
public protocol GraphRequestProtocol {
  associatedtype Response: GraphResponseProtocol

  /// The Graph API endpoint to use for the request, e.g. `"me"`.
  var graphPath: String { get }

  /// The request parameters.
  var parameters: [String : Any]? { get }

  /// The `AccessToken` used by the request to authenticate.
  var accessToken: AccessToken? { get }

  /// The `HTTPMethod` to use for the request, e.g. `.GET`/`.POST`/`.DELETE`.
  var httpMethod: GraphRequestHTTPMethod { get }

  /// Graph API Version to use. Default: `GraphAPIVersion.defaultVersion`.
  var apiVersion: GraphAPIVersion { get }
}

extension GraphRequestProtocol {
  /**
   A convenience method that creates and starts a connection to the Graph API.

   - parameter completion: Optional completion closure that is going to be called when the connection finishes or fails.
   */
  public func start(_ completion: GraphRequestConnection.Completion<Self>? = nil) {
    let connection = GraphRequestConnection()
    connection.add(self, completion: completion)
    connection.start()
  }
}

/**
 Represents HTTP methods that could be used to issue `GraphRequestProtocol`.
 */
public enum GraphRequestHTTPMethod: String {
  /// `GET` graph request HTTP method.
  case GET = "GET"
  /// `POST` graph request HTTP method.
  case POST = "POST"
  /// `DELETE` graph request HTTP method.
  case DELETE = "DELETE"
}
