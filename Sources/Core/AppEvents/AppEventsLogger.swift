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

import FBSDKCoreKit.FBSDKAppEvents
import Foundation

/**
 Client-side event logging for specialized application analytics available through Facebook App Insights
 and for use with Facebook Ads conversion tracking and optimization.

 The `AppEventsLogger` static class has a few related roles:

 * Logging predefined and application-defined events to Facebook App Insights with a
 numeric value to sum across a large number of events, and an optional set of key/value
 parameters that define "segments" for this event (e.g., 'purchaserStatus' : 'frequent', or
 'gamerLevel' : 'intermediate')

 * Logging events to later be used for ads optimization around lifetime value.

 * Methods that control the way in which events are flushed out to the Facebook servers.

 Here are some important characteristics of the logging mechanism provided by `AppEventsLogger`:

 * Events are not sent immediately when logged. They're cached and flushed out to the Facebook servers
 in a number of situations:
 * when an event count threshold is passed (currently 100 logged events).
 * when a time threshold is passed (currently 15 seconds).
 * when an app has gone to background and is then brought back to the foreground.

 * Events will be accumulated when the app is in a disconnected state, and sent when the connection is
 restored and one of the above 'flush' conditions are met.

 * The `AppEventsLogger` class is thread-safe in that events may be logged from any of the app's threads.

 * The developer can set the `flushBehavior` to force the flushing of events to only
 occur on an explicit call to the `flush` method.

 * The developer can turn on console debug output for event logging and flushing to the server by using
 the `FBSDKLoggingBehaviorAppEvents` value in `[FBSettings setLoggingBehavior:]`.

 Some things to note when logging events:

 * There is a limit on the number of unique event names an app can use, on the order of 1000.
 * There is a limit to the number of unique parameter names in the provided parameters that can be used per event,
 on the order of 25. This is not just for an individual call, but for all invocations for that eventName.
 * Event names and parameter names (the keys in the Dictionary) must be between 2 and 40 characters,
 and must consist of alphanumeric characters, _, -, or spaces.
 * The length of each parameter value can be no more than on the order of 100 characters.
 */
public enum AppEventsLogger {

  public typealias UpdateUserPropertiesCompletion =
    (_ httpResponse: HTTPURLResponse?, _ result: GraphRequestResult<GraphRequest>) -> Void

  //--------------------------------------
  // MARK: - Activate
  //--------------------------------------

  /**
   Notifies the events system that the app has launched and, when appropriate, logs an "activated app" event.
   Should typically be placed in the app delegates' `applicationDidBecomeActive()` function.

   This method also takes care of logging the event indicating the first time this app has been launched,
   which, among other things, is used to track user acquisition and app install ads conversions.

   `activate()` will not log an event on every app launch,
   since launches happen every time the app is backgrounded and then foregrounded.
   "activated app" events will be logged when the app has not been active for more than 60 seconds.
   This method also causes a "deactivated app" event to be logged when sessions are "completed",
   and these events are logged with the session length,
   with an indication of how much time has elapsed between sessions,
   and with the number of background/foreground interruptions that session had.
   This data is all visible in your app's App Events Insights.

   - parameter application: Optional instance of UIApplication. Default: `UIApplication.sharedApplication()`.
   */
  public static func activate(_ application: UIApplication = UIApplication.shared) {
    FBSDKAppEvents.activateApp()
  }

  //--------------------------------------
  // MARK: - Log Events
  //--------------------------------------

  /**
   Log an app event.

   - parameter event: The application event to log.
   - parameter accessToken: Optional access token to use to log the event. Default: `AccessToken.current`.
   */
  public static func log(_ event: AppEventLoggable, accessToken: AccessToken? = AccessToken.current) {
    let valueToSum = event.valueToSum.map { NSNumber(value: $0 as Double) }
    let parameters = event.parameters.keyValueMap {
      ($0.0.rawValue as NSString, $0.1.appEventParameterValue)
    }
    FBSDKAppEvents.logEvent(event.name.rawValue,
                            valueToSum: valueToSum,
                            parameters: parameters,
                            accessToken: accessToken?.sdkAccessTokenRepresentation)
  }

  /**
   Log an app event.

   This overload is required, so dot-syntax works in this example:
   ```
   AppEventsLogger().log(.Searched())
   ```

   - parameter event: The application event to log.
   - parameter accessToken: Optional access token to use to log the event. Default: `AccessToken.current`.
   */
  public static func log(_ event: AppEvent, accessToken: AccessToken? = AccessToken.current) {
    log(event as AppEventLoggable, accessToken: accessToken)
  }

  /**
   Log an app event.

   - parameter eventName: The name of the event to record.
   - parameter parameters: Arbitrary parameter dictionary of characteristics.
   - parameter valueToSum: Amount to be aggregated into all events of this eventName, and App Insights will report
   the cumulative and average value of this amount.
   - parameter accessToken: The optional access token to log the event as. Default: `AccessToken.current`.
   */
  public static func log(_ eventName: String,
                         parameters: AppEvent.ParametersDictionary = [:],
                         valueToSum: Double? = nil,
                         accessToken: AccessToken? = AccessToken.current) {
    let event = AppEvent(name: AppEventName(eventName), parameters: parameters, valueToSum: valueToSum)
    log(event, accessToken: accessToken)
  }

  //--------------------------------------
  // MARK: - Push Notifications
  //--------------------------------------

  /**
   Sets a device token to register the current application installation for push notifications.
   */
  public static var pushNotificationsDeviceToken: Data? {
    didSet {
      FBSDKAppEvents.setPushNotificationsDeviceToken(pushNotificationsDeviceToken)
    }
  }

  //--------------------------------------
  // MARK: - Flush
  //--------------------------------------

  /**
   The current event flushing behavior specifying when events are sent to Facebook.
   */
  public static var flushBehavior: FlushBehavior {
    get {
      return FlushBehavior(sdkFlushBehavior: FBSDKAppEvents.flushBehavior())
    }
    set {
      FBSDKAppEvents.setFlushBehavior(newValue.sdkFlushBehavior)
    }
  }

  /**
   Explicitly kick off flushing of events to Facebook.
   This is an asynchronous method, but it does initiate an immediate kick off.
   Server failures will be reported through the NotificationCenter with notification ID
   `FBSDKAppEventsLoggingResultNotification`.
   */
  public static func flush() {
    FBSDKAppEvents.flush()
  }

  //--------------------------------------
  // MARK: - Override App Id
  //--------------------------------------

  /**
   Facebook application id that is going to be used for logging all app events.

   In some cases, you might want to use one Facebook App ID for login
   and social presence and another for App Event logging.
   (An example is if multiple apps from the same company share an app ID for login, but want distinct logging.)
   By default, this value defers to the `FBSDKAppEventsOverrideAppIDBundleKey` plist value.
   If that's not set, it defaults to `FBSDKSettings.appId`.
   */
  public static var loggingAppId: String? {
    get {
      if let appId = FBSDKAppEvents.loggingOverrideAppID() {
        return appId
      }
      return FBSDKSettings.appID()
    }
    set {
      return FBSDKAppEvents.setLoggingOverrideAppID(newValue)
    }
  }

  //--------------------------------------
  // MARK: - User Id
  //--------------------------------------

  ///
  /// A custom user identifier to associate with all app events.
  /// The `userId` is persisted until it is cleared by passing `nil`.
  ///
  public static var userId: String? {
    get {
      return FBSDKAppEvents.userID() as String?
    }
    set {
      FBSDKAppEvents.setUserID(newValue)
    }
  }

  //--------------------------------------
  // MARK: - User Parameters
  //--------------------------------------

  /**
   Sends a request to update the properties for the current user, set by `AppEventsLogger.userId`.

   - parameter properties: A dictionary of key-value pairs representing user properties and their values.
   Values should be strings or numbers only. Each key must be less than 40 character in length,
   and the key can contain only letters, number, whitespace, hyphens (`-`), or underscores (`_`).
   Each value must be less than 100 characters.
   - parameter completion: Optional completion closure that is going to be called when the request finishes or fails.
   */
  public static func updateUserProperties(_ properties: [String: Any],
                                          completion: @escaping UpdateUserPropertiesCompletion) {
    FBSDKAppEvents.updateUserProperties(properties,
                                        handler: GraphRequestConnection.sdkRequestCompletion(from: completion))
  }
}
