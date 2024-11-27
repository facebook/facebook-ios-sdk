/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import Foundation

/**
 Represents a pending request to navigate to an app link. Instead of simplying opening a URL, you can build custom requests with additional navigation and app data attached to them by creating an `AppLinkNavigation`.
 */
@objcMembers
@objc(FBSDKAppLinkNavigation)
@available(iOSApplicationExtension, unavailable, message: "Not available in app extension")
public final class AppLinkNavigation: NSObject {

  @nonobjc
  @available(
    *,
    deprecated,
    message: """
      This property is deprecated and will be removed in the next major release. \
      Use `defaultResolver` instead.
      """
  )

  public static var `default`: AppLinkResolving {
    get { defaultResolver }
    set { defaultResolver = newValue }
  }

  /**
   The default resolver to be used for App Link resolution. If the developer has not set one explicitly,
   a basic, built-in `WebViewAppLinkResolver` will be used.
   */
  @objc(defaultResolver)
  public static var defaultResolver: AppLinkResolving {
    get {
      // swiftformat:disable:next redundantSelf
      self.appLinkResolver ?? WebViewAppLinkResolver.shared
    }

    set {
      guard var dependencies = try? getDependencies() else {
        return
      }

      dependencies.appLinkResolver = newValue
      setDependencies(dependencies)
    }
  }

  /**
   The extras for the AppLinkNavigation. This will generally contain application-specific
   data that should be passed along with the request, such as advertiser or affiliate IDs or
   other such metadata relevant on this device.
   */
  public let extras: [String: Any]

  /**
   The al_applink_data for the AppLinkNavigation. This will generally contain data common to
   navigation attempts such as back-links, user agents, and other information that may be used
   in routing and handling an App Link request.
   */
  public let appLinkData: [String: Any]

  /// The AppLink to navigate to
  public let appLink: AppLink?

  private var lastNavError: Error?
  static let maxDepth = 32

  typealias AppLinkNavigationFallbackBlock = (Error?) -> Void

  /**
   Returns navigation type for current instance. It does not produce any side-effects as the `navigate` method.
   */
  public var navigationType: AppLinkNavigationType {
    navigationType(for: appLink?.targets)
  }

  /// Creates an AppLinkNavigation with the given link, extras, and App Link data
  @objc(initWithAppLink:extras:appLinkData:)
  public init(appLink: AppLink?, extras: [String: Any], appLinkData: [String: Any]) {
    self.appLink = appLink
    self.extras = extras
    self.appLinkData = appLinkData
  }

  /// Creates an AppLinkNavigation with the given link, extras,  App Link data and settings
  @available(
    *,
    deprecated,
    message: """
      Please use init(appLink:extras:appLinkData:) to instantiate an `AppLinkNavigation`.
      This method will be removed in the next major version."
      """
  )
  @objc(initWithAppLink:extras:appLinkData:settings:)
  public convenience init(
    appLink: AppLink,
    extras: [String: Any],
    appLinkData: [String: Any],
    settings: SettingsProtocol
  ) {
    self.init(appLink: appLink, extras: extras, appLinkData: appLinkData)
  }

  /// Creates an AppLinkNavigation with the given link, extras, and App Link data. The `settings` argument will be ignored in favor of internal dependency injection.
  @available(
    *,
    deprecated,
    message: """
      Please use designated init to instantiate an AppLinkNavigation. This method will be removed in future releases."
      """
  )
  @objc(navigationWithAppLink:extras:appLinkData:settings:)
  public static func navigation(
    with appLink: AppLink?,
    extras: [String: Any],
    appLinkData: [String: Any],
    settings: SettingsProtocol
  ) -> AppLinkNavigation {
    AppLinkNavigation(appLink: appLink, extras: extras, appLinkData: appLinkData)
  }

  /**
   Creates an instance of `[String: [String: String]]` with the correct format for iOS callback URLs to be used as 'appLinkData' argument in the call to init(appLink:extras:appLinkData:).
   */
  @objc(callbackAppLinkDataForAppWithName:url:)
  public static func callbackAppLinkData(forApp appName: String, url: String) -> [String: [String: String]] {
    [FBSDKAppLinkRefererAppLink: [FBSDKAppLinkRefererAppName: appName, FBSDKAppLinkRefererUrl: url]]
  }

  /// Performs the navigation
  @objc(navigate:)
  public func navigate(handler: AppLinkNavigationBlock?) {
    let urlOpener: _InternalURLOpener
    do {
      urlOpener = try Self.getDependencies().urlOpener
    } catch {
      handler?(.failure, error)
      return
    }

    guard let appLink else {
      handler?(.failure, nil)
      return
    }

    let fallbackBlock: AppLinkNavigationFallbackBlock = { lastError in
      self.openInBrowserIfAvailable(urlOpener: urlOpener, lastError: lastError, handler: handler)
    }
    findAndOpenFirstLaunchableTarget(
      targets: appLink.targets,
      urlOpener: urlOpener,
      fallbackBlock: fallbackBlock,
      handler: handler
    )
  }

  private func findAndOpenFirstLaunchableTarget(
    targets: [AppLinkTargetProtocol],
    urlOpener: _InternalURLOpener,
    fallbackBlock: @escaping AppLinkNavigationFallbackBlock,
    handler: AppLinkNavigationBlock?
  ) {
    // Find the first eligible/launchable target in the AppLink and open.
    lastNavError = nil
    findAndOpenFirstLaunchableTarget(
      targets: targets,
      urlOpener: urlOpener,
      index: 0,
      fallbackBlock: fallbackBlock,
      handler: handler
    )
  }

  private func findAndOpenFirstLaunchableTarget(
    targets: [AppLinkTargetProtocol],
    urlOpener: _InternalURLOpener,
    index: Int,
    fallbackBlock: @escaping AppLinkNavigationFallbackBlock,
    handler: AppLinkNavigationBlock?
  ) {
    // Use recursion as the calls need to be chained within the async callback.
    // Limit the number of link targets to avoid stack overflow.
    if index >= targets.count || index >= AppLinkNavigation.maxDepth {
      // Fall back to opening the url in the browser if available.
      fallbackBlock(lastNavError)
      return
    }

    do {
      if let targetURL = targets[index].url,
         let appLinkURL = try appLinkURL(targetURL: targetURL) {
        urlOpener.open(appLinkURL, options: [:]) { [weak self] success in
          if success {
            let openedURL = appLinkURL
            let navigationType: AppLinkNavigationType = .app
            self?.postNavigateEventNotification(
              targetURL: openedURL,
              error: self?.lastNavError,
              navigationType: navigationType
            )
            handler?(navigationType, self?.lastNavError)
            return
          } else {
            self?.findAndOpenFirstLaunchableTarget(
              targets: targets,
              urlOpener: urlOpener,
              index: index + 1,
              fallbackBlock: fallbackBlock,
              handler: handler
            )
          }
        }
      } else {
        findAndOpenFirstLaunchableTarget(
          targets: targets,
          urlOpener: urlOpener,
          index: index + 1,
          fallbackBlock: fallbackBlock,
          handler: handler
        )
      }
    } catch {
      lastNavError = error
      findAndOpenFirstLaunchableTarget(
        targets: targets,
        urlOpener: urlOpener,
        index: index + 1,
        fallbackBlock: fallbackBlock,
        handler: handler
      )
    }
  }

  private func openInBrowserIfAvailable(
    urlOpener: _InternalURLOpener,
    lastError: Error?,
    handler: AppLinkNavigationBlock?
  ) {
    // Fall back to opening the url in the browser if available.
    var navigationType: AppLinkNavigationType = .failure
    var openedURL: URL?
    do {
      if let webURL = appLink?.webURL,
         let appLinkBrowserURL = try appLinkURL(targetURL: webURL),
         urlOpener.canOpen(appLinkBrowserURL) {
        urlOpener.open(appLinkBrowserURL, options: [:]) { success in
          if success {
            openedURL = appLinkBrowserURL
            navigationType = .browser
          }
          self.postNavigateEventNotification(targetURL: openedURL, error: lastError, navigationType: navigationType)
          handler?(navigationType, lastError)
        }
      } else {
        postNavigateEventNotification(targetURL: openedURL, error: lastError, navigationType: navigationType)
        handler?(navigationType, lastError)
      }
    } catch {
      postNavigateEventNotification(targetURL: openedURL, error: error, navigationType: navigationType)
      handler?(navigationType, error)
    }
  }

  /// Returns an AppLink for the given URL
  @objc(resolveAppLink:handler:)
  public static func resolveAppLink(_ destination: URL, handler: @escaping AppLinkBlock) {
    // swiftformat:disable:next redundantSelf
    guard let appLinkResolver = self.appLinkResolver else { return }

    resolveAppLink(destination, resolver: appLinkResolver, handler: handler)
  }

  /// Returns an AppLink for the given URL using the given App Link resolution strategy
  @objc(resolveAppLink:resolver:handler:)
  public static func resolveAppLink(_ destination: URL, resolver: AppLinkResolving, handler: @escaping AppLinkBlock) {
    resolver.appLink(from: destination, handler: handler)
  }

  @objc(navigateToAppLink:handler:)
  public static func navigate(to appLink: AppLink, handler: @escaping AppLinkNavigationBlock) {
    AppLinkNavigation(appLink: appLink, extras: [:], appLinkData: [:]).navigate(handler: handler)
  }

  /**
   Returns an AppLinkNavigationType based on a FBSDKAppLink.
   It's essentially a no-side-effect version of navigateToAppLink:error:,
   allowing apps to determine flow based on the link type (e.g. open an
   internal web view instead of going straight to the browser for regular links.)
   */
  @objc(navigationTypeForLink:)
  public static func navigationType(for appLink: AppLink) -> AppLinkNavigationType {
    AppLinkNavigation(appLink: appLink, extras: [:], appLinkData: [:]).navigationType
  }

  /// Navigates to a URL (an asynchronous action) and returns a NavigationType
  @objc(navigateToURL:handler:)
  public static func navigate(to destination: URL, handler: @escaping AppLinkNavigationBlock) {
    // swiftformat:disable:next redundantSelf
    guard let appLinkResolver = self.appLinkResolver else { return }

    navigate(to: destination, resolver: appLinkResolver, handler: handler)
  }

  /**
   Navigates to a URL (an asynchronous action) using the given App Link resolution
   strategy and returns a NavigationType
   */
  @objc(navigateToURL:resolver:handler:)
  public static func navigate(
    to destination: URL,
    resolver: AppLinkResolving,
    handler: @escaping AppLinkNavigationBlock
  ) {
    DispatchQueue.main.async {
      resolveAppLink(destination, resolver: resolver) { appLink, error in
        guard
          let appLink = appLink,
          error == nil
        else {
          handler(.failure, error)
          return
        }

        navigate(to: appLink, handler: handler)
      }
    }
  }

  func appLinkURL(targetURL: URL) throws -> URL? {
    let settings = try Self.getDependencies().settings
    var appLinkData = appLinkData

    // Add applink protocol data
    if appLinkData[FBSDKAppLinkUserAgentKeyName] == nil {
      appLinkData[FBSDKAppLinkUserAgentKeyName] = "FBSDK \(settings.sdkVersion)"
    }

    if appLinkData[FBSDKAppLinkVersionKeyName] == nil {
      appLinkData[FBSDKAppLinkVersionKeyName] = AppLinkVersion
    }

    if let rawURL = appLink?.sourceURL?.absoluteString {
      appLinkData[FBSDKAppLinkTargetKeyName] = rawURL
    }

    appLinkData[FBSDKAppLinkExtrasKeyName] = extras

    if JSONSerialization.isValidJSONObject(appLinkData) {
      // JSON-ify the applink data
      let jsonData = try JSONSerialization.data(withJSONObject: appLinkData)
      let jsonString = String(data: jsonData, encoding: .utf8)
      let encodedString = jsonString?.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
      let endURLString = """
        \(targetURL.absoluteString)\(targetURL.query != nil ? "&" : "?")\(FBSDKAppLinkDataParameterName)=\(encodedString)
        """
      return URL(string: endURLString)
    } else {
      throw NSError(domain: "JSON object not valid", code: -1)
    }
  }

  private enum LogDataKeys {
    static let outputURLScheme = "outputURLScheme"
    static let outputURL = "outputURL"
    static let sourceURL = "sourceURL"
    static let sourceHost = "sourceHost"
    static let sourceScheme = "sourceScheme"
    static let success = "success"
    static let type = "type"
    static let error = "error"
  }

  private enum EventValues {
    static let success = "1"
    static let failure = "0"

    static func getEventType(for navigationType: AppLinkNavigationType) -> (String?, String?) {
      switch navigationType {
      case .failure: return (failure, "fail")
      case .browser: return (success, "web")
      case .app: return (success, "app")
      @unknown default:
        return (nil, nil)
      }
    }
  }

  func postNavigateEventNotification(targetURL: URL?, error: Error?, navigationType: AppLinkNavigationType) {
    guard let appLinkEventPoster = Self.appLinkEventPoster else { return }

    var logData = [String: Any]()
    logData[LogDataKeys.outputURLScheme] = targetURL?.scheme
    logData[LogDataKeys.outputURL] = targetURL?.absoluteString
    logData[LogDataKeys.sourceURL] = appLink?.sourceURL?.absoluteString
    logData[LogDataKeys.sourceHost] = appLink?.sourceURL?.host
    logData[LogDataKeys.sourceScheme] = appLink?.sourceURL?.scheme
    logData[LogDataKeys.error] = error?.localizedDescription

    let (result, type) = EventValues.getEventType(for: navigationType)
    logData[LogDataKeys.success] = result
    logData[LogDataKeys.type] = type

    if let appLink, appLink.isBackToReferrer {
      appLinkEventPoster.postNotification(
        eventName: AppLinkNavigateBackToReferrerEventName,
        arguments: logData
      )
    } else {
      appLinkEventPoster.postNotification(
        eventName: AppLinkNavigateOutEventName,
        arguments: logData
      )
    }
  }

  func navigationType(for targets: [AppLinkTargetProtocol]?) -> AppLinkNavigationType {
    guard let targets else { return .failure }
    guard let urlOpener = Self.urlOpener else { return .failure }

    let eligibleTarget = targets.first { target in
      guard let url = target.url else { return false }

      return urlOpener.canOpen(url)
    }

    if let eligibleTargetURL = eligibleTarget?.url,
       (try? appLinkURL(targetURL: eligibleTargetURL)) != nil {
      return .app
    } else if let webURL = appLink?.webURL,
              (try? appLinkURL(targetURL: webURL)) != nil {
      return .browser
    } else {
      return .failure
    }
  }
}

extension AppLinkNavigation: DependentAsType {
  struct TypeDependencies {
    var settings: SettingsProtocol
    var urlOpener: _InternalURLOpener
    var appLinkEventPoster: _AppLinkEventPosting
    var appLinkResolver: AppLinkResolving
  }

  static var configuredDependencies: TypeDependencies?
  static var defaultDependencies: TypeDependencies?
}
