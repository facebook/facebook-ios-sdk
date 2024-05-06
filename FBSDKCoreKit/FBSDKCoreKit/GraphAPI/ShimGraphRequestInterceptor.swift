/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import AuthenticationServices
import Foundation

/**
 Internal class exposed to facilitate transition to Swift.
 API Subject to change or removal without warning. Do not use.

 @warning INTERNAL - DO NOT USE
 */
@objcMembers
@objc(FBSDKShimGraphRequestInterceptor)
public final class ShimGraphRequestInterceptor: NSObject {

  private enum GraphAPIPath: String, CaseIterable {
    // swiftlint:disable:next identifier_name
    case me = "/me"
    case friends = "/friends"
    case picture = "/picture"
    // Add more cases as needed

    static var regexPattern: String {
      // Map each case to its raw value, escape the slashes for the regex, and join them with "|"
      let graphAPIPaths: [GraphAPIPath] = [.friends, .picture]
      let paths = graphAPIPaths
        .map { $0.rawValue.replacingOccurrences(of: "/", with: "\\/") }
        .joined(separator: "|")

      // This part of the regex matches the optional version prefix, e.g. "/v17.0"
      // "\\/v\\d+\\.\\d+" matches "/v", followed by one or more digits, ".", and one or more digits
      // The "?" makes this part optional
      let versionPattern = "(\\/v\\d+\\.\\d+)?"

      // This part of the regex matches the path
      // "\(paths)" matches any of the paths generated from the enum cases
      // The "?" makes this part optional
      let pathPattern = "(\(paths))?"

      // The "^" at the start and "$" at the end ensure that the entire string must match the pattern
      // The full regex matches an optional version prefix, followed by a slash, followed by one of the paths
      return "^\(versionPattern)\\/me\(pathPattern)$"
    }
  }

  private enum GraphAPIResponseKeys: String {
    case accessToken = "access_token"
    case format
    case includesHeaders = "include_headers"
    case sdk
    case contentType = "Content-Type"
    case redirect
  }

  private enum GraphAPIResponseValues: String {
    case json
    case `false`
    case ios
    case imageType = "image/jpeg"
    case pictureRedirectData = "0"
  }

  public static let shared = ShimGraphRequestInterceptor()
  private var urlResponseURLComponents: URLComponents?
  private var currentGraphAPIPath: GraphAPIPath = .me
  private var currentURLRequest: URLRequest?

  // MARK: - Request Interception

  @objc(shouldInterceptRequest:)
  public func shouldInterceptRequest(_ request: URLRequest) -> Bool {
    if _DomainHandler.sharedInstance().isDomainHandlingEnabled(), !Settings.shared.isAdvertiserTrackingEnabled {
      return isGraphAPIShimSupportedRequest(request)
    } else {
      return false
    }
  }

  private func isGraphAPIShimSupportedRequest(_ request: URLRequest) -> Bool {
    guard let urlPath = request.url?.path else {
      return false
    }

    if urlPath.range(of: GraphAPIPath.regexPattern, options: .regularExpression) != nil {
      for path in GraphAPIPath.allCases {
        if urlPath.hasSuffix(path.rawValue) {
          currentGraphAPIPath = path
          currentURLRequest = request
          return true
        }
      }
    }

    return false
  }

  private func shouldSendPictureData(for request: URLRequest) -> Bool {
    guard let url = request.url,
          let urlComponents = URLComponents(string: url.absoluteString),
          let queries = urlComponents.queryItems
    else {
      return false
    }

    for query in queries {
      if query.name == GraphAPIResponseKeys.redirect.rawValue,
         let redirect = query.value,
         redirect == GraphAPIResponseValues.pictureRedirectData.rawValue {
        return true
      }
    }

    return false
  }

  private func handlePictureData(_ urlResponse: URL, completionHandler: @escaping UrlSessionTaskBlock) {
    var httpURLResponse = HTTPURLResponse(url: urlResponse, statusCode: 200, httpVersion: nil, headerFields: nil)

    guard let currentURLRequest = currentURLRequest, shouldSendPictureData(for: currentURLRequest) else {
      let headerFields = [GraphAPIResponseKeys.contentType.rawValue: GraphAPIResponseValues.imageType.rawValue]
      httpURLResponse = HTTPURLResponse(
        url: urlResponse,
        statusCode: 200,
        httpVersion: nil,
        headerFields: headerFields
      )
      completionHandler(nil, httpURLResponse, nil)
      return
    }

    let responseData = Profile.current?.pictureData
    completionHandler(responseData, httpURLResponse, nil)
  }

  // MARK: - Requests Handling

  @objc(executeWithRequest:completionHandler:)
  public func execute(request: URLRequest, completionHandler: @escaping UrlSessionTaskBlock) {
    if let urlString = request.url?.absoluteString {
      urlResponseURLComponents = URLComponents(string: urlString)
    }
    makeShimRequest(completionHandler: completionHandler)
  }

  func makeShimRequest(completionHandler: @escaping UrlSessionTaskBlock) {
    let nsError = NSError(domain: "Could not make graph API request", code: -1, userInfo: nil)

    guard
      let urlResponseURLComponents = urlResponseURLComponents?.url,
      let scheme = urlResponseURLComponents.scheme,
      let host = urlResponseURLComponents.host
    else {
      completionHandler(nil, nil, nsError)
      return
    }
    let path = urlResponseURLComponents.path
    let baseURLString = "\(scheme)://\(host)\(path)"

    var urlComponents = URLComponents(string: baseURLString)
    urlComponents?.queryItems = [
      URLQueryItem(name: GraphAPIResponseKeys.accessToken.rawValue, value: AccessToken.current?.tokenString),
      URLQueryItem(name: GraphAPIResponseKeys.format.rawValue, value: GraphAPIResponseValues.json.rawValue),
      URLQueryItem(name: GraphAPIResponseKeys.includesHeaders.rawValue, value: GraphAPIResponseValues.false.rawValue),
      URLQueryItem(name: GraphAPIResponseKeys.sdk.rawValue, value: GraphAPIResponseValues.ios.rawValue),
    ]

    guard let responseURL = urlComponents?.url else {
      completionHandler(nil, nil, nsError)
      return
    }

    let httpURLResponse = HTTPURLResponse(url: responseURL, statusCode: 200, httpVersion: nil, headerFields: nil)

    var responseData: Data?
    switch currentGraphAPIPath {
    case .me:
      responseData = Profile.current?.profileToData
    case .friends:
      responseData = Profile.current?.userFriendsData
    case .picture:
      handlePictureData(responseURL, completionHandler: completionHandler)
      return
    }
    guard let responseData = responseData else {
      completionHandler(nil, nil, nsError)
      return
    }
    completionHandler(responseData, httpURLResponse, nil)
  }
}
