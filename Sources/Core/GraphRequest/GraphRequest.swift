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
 Represents a request to the Facebook Graph API.

 `GraphRequest` encapsulates the components of a request (the Graph API path, the parameters, error recovery behavior)
 and should be used in conjunction with `GraphRequestConnection` to issue the request.

 Nearly all Graph APIs require an access token.
 Unless specified, the `AccessToken.current` is used. Therefore, most requests
 will require login first (see `LoginManager` in `FacebookLogin.framework`).
 */
public struct GraphRequest: GraphRequestProtocol {
  public typealias Response = GraphResponse

  /// The Graph API endpoint to use for the request, e.g. `"me"`.
  public let graphPath: String

  /// The request parameters.
  public var parameters: [String: Any]?

  /// The `AccessToken` used by the request to authenticate.
  public let accessToken: AccessToken?

  /// The `HTTPMethod` to use for the request, e.g. `.GET`/`.POST`/`.DELETE`.
  public let httpMethod: GraphRequestHTTPMethod

  /// Graph API Version to use, e.g. `"2.7"`. Default: `GraphAPIVersion.defaultVersion`.
  public let apiVersion: GraphAPIVersion

  /**
   Initializes a new instance of graph request.

   - parameter graphPath: The Graph API endpoint to use for the request.
   - parameter parameters: Optional parameters dictionary.
   - parameter accessToken: Optional authentication token to use. Defaults to `AccessToken.current`.
   - parameter httpMethod: Optional `GraphRequestHTTPMethod` to use for the request. Defaults to `.GET`.
   - parameter apiVersion: Optional Graph API version to use. Defaults to `GraphAPIVersion.Default`.
   */
  public init(graphPath: String,
              parameters: [String: Any] = [:],
              accessToken: AccessToken? = AccessToken.current,
              httpMethod: GraphRequestHTTPMethod = .GET,
              apiVersion: GraphAPIVersion = .defaultVersion) {
    self.graphPath = graphPath
    self.parameters = parameters
    self.accessToken = accessToken
    self.httpMethod = httpMethod
    self.apiVersion = apiVersion
  }
}
