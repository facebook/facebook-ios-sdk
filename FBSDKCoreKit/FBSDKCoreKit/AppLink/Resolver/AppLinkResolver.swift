/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import Foundation

/**
 Provides an implementation of the AppLinkResolving protocol that uses the Facebook App Link
 Index API to resolve App Links given a URL. It also provides an additional helper method that can resolve
 multiple App Links in a single call.
 */
@objcMembers
@objc(FBSDKAppLinkResolver)
public final class AppLinkResolver: NSObject, AppLinkResolving {
  var cachedAppLinks = NSMutableDictionary()

  private enum Keys {
    static let url = "url"
    static let iosAppStoreId = "app_store_id"
    static let iosAppName = "app_name"
    static let web = "web"
    static let ios = "ios"
    static let iphone = "iphone"
    static let ipad = "ipad"
    static let shouldFallBack = "should_fallback"
    static let appLinks = "app_links"
  }

  public func appLink(from url: URL, handler: @escaping AppLinkBlock) {
    appLinks(from: [url]) { urls, error in
      handler(urls[url], error)
    }
  }

  /**
   Asynchronously resolves App Link data for a given array of URLs.

   @param urls The URLs to resolve into an App Link.
   @param handler The completion block that will return an App Link for the given URL.
   */
  @available(iOSApplicationExtension, unavailable, message: "Not available in app extension")
  public func appLinks(from urls: [URL], handler: @escaping AppLinksBlock) {
    guard let dependencies = try? Self.getDependencies() else {
      handler([:], nil)
      return
    }

    if dependencies.clientTokenProvider.clientToken == nil,
       dependencies.accessTokenProvider.current == nil {
      _Logger.singleShotLogEntry(
        .developerErrors,
        logEntry: "A user access token or clientToken is required to use AppLinkResolver"
      )
    }

    var appLinks = [URL: AppLink]()
    var appLinkURLs = [URL]()

    synchronized(cachedAppLinks) {
      for url in urls {
        if let cachedAppLink = cachedAppLinks[url] as? AppLink {
          appLinks[url] = cachedAppLink
        } else {
          appLinkURLs.append(url)
        }
      }
    }

    guard !appLinkURLs.isEmpty else {
      // All of the URLs have already been found.
      handler(appLinks, nil)
      return
    }

    let request = dependencies.requestBuilder.request(for: urls)

    request.start { _, response, error in

      guard
        error == nil,
        let response = response as? [String: [String: Any]]
      else {
        handler([:], error)
        return
      }

      for url in appLinkURLs {
        let link = self.buildAppLink(for: url, result: response)

        synchronized(self.cachedAppLinks) {
          self.cachedAppLinks[url] = link
        }

        appLinks[url] = link
      }

      handler(appLinks, nil)
    }
  }

  func buildAppLink(for url: URL, result: [String: [String: Any]]) -> AppLink {
    guard let requestBuilder = try? Self.getDependencies().requestBuilder else {
      fatalError("Dependencies have not been set")
    }

    let nestedObject = result[url.absoluteString]?[Keys.appLinks] as? [String: Any] ?? [:]
    var rawTargets = [[String: String]]()

    if let idiomSpecificField = requestBuilder.getIdiomSpecificField(),
       let idiomSpecificFields = nestedObject[idiomSpecificField] as? [[String: String]] {
      rawTargets.append(contentsOf: idiomSpecificFields)
    }

    if let iOSFields = nestedObject[Keys.ios] as? [[String: String]] {
      rawTargets.append(contentsOf: iOSFields)
    }

    var targets = [AppLinkTarget]()

    for rawTarget in rawTargets {
      let urlString = rawTarget[Keys.url]
      let url = URL(string: urlString ?? "")
      let appStoreID = rawTarget[Keys.iosAppStoreId]
      let appName = rawTarget[Keys.iosAppName]
      let appLinkTarget = AppLinkTarget(url: url, appStoreId: appStoreID, appName: appName ?? "")
      targets.append(appLinkTarget)
    }

    let webTarget = nestedObject[Keys.web] as? [String: Any] ?? [:]
    let webFallbackString = webTarget[Keys.url] as? String ?? ""
    var fallbackURL: URL? = URL(string: webFallbackString) ?? url

    if let shouldFallback = webTarget[Keys.shouldFallBack] as? Bool,
       !shouldFallback {
      fallbackURL = nil
    }

    return AppLink(sourceURL: url, targets: targets, webURL: fallbackURL)
  }
}

extension AppLinkResolver: DependentAsType {
  struct TypeDependencies {
    var requestBuilder: _AppLinkResolverRequestBuilding
    var clientTokenProvider: _ClientTokenProviding
    var accessTokenProvider: _AccessTokenProviding.Type
  }

  static var configuredDependencies: TypeDependencies?

  static var defaultDependencies: TypeDependencies? = TypeDependencies(
    requestBuilder: AppLinkResolverRequestBuilder(),
    clientTokenProvider: Settings.shared,
    accessTokenProvider: AccessToken.self
  )
}
