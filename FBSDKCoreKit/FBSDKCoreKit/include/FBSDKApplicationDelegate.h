/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <UIKit/UIKit.h>

#import <FBSDKCoreKit/FBSDKApplicationObserving.h>

NS_ASSUME_NONNULL_BEGIN

/**
 The FBSDKApplicationDelegate is designed to post process the results from Facebook Login
 or Facebook Dialogs (or any action that requires switching over to the native Facebook
 app or Safari).

 The methods in this class are designed to mirror those in UIApplicationDelegate, and you
 should call them in the respective methods in your AppDelegate implementation.
 */
NS_SWIFT_NAME(ApplicationDelegate)
@interface FBSDKApplicationDelegate : NSObject

#if !FBTEST
- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;
#endif

#if DEBUG && FBTEST
@property (nonnull, nonatomic, readonly) NSHashTable<id<FBSDKApplicationObserving>> *applicationObservers;
#endif

/// Gets the singleton instance.
@property (class, nonatomic, readonly, strong) FBSDKApplicationDelegate *sharedInstance
NS_SWIFT_NAME(shared);

/**
 Call this method from the [UIApplicationDelegate application:continue:restorationHandler:] method
 of the AppDelegate for your app. It should be invoked in order to properly process the web URL (universal link)
 once the end user is redirected to your app.

 @param application The application as passed to [UIApplicationDelegate application:continue:restorationHandler:].
 @param userActivity The user activity as passed to [UIApplicationDelegate application:continue:restorationHandler:].

 @return YES if the URL was intended for the Facebook SDK, NO if not.
*/
- (BOOL)application:(UIApplication *)application continueUserActivity:(NSUserActivity *)userActivity;

/**
 Call this method from the [UIApplicationDelegate application:openURL:sourceApplication:annotation:] method
 of the AppDelegate for your app. It should be invoked for the proper processing of responses during interaction
 with the native Facebook app or Safari as part of SSO authorization flow or Facebook dialogs.

 @param application The application as passed to [UIApplicationDelegate application:openURL:sourceApplication:annotation:].

 @param url The URL as passed to [UIApplicationDelegate application:openURL:sourceApplication:annotation:].

 @param sourceApplication The sourceApplication as passed to [UIApplicationDelegate application:openURL:sourceApplication:annotation:].

 @param annotation The annotation as passed to [UIApplicationDelegate application:openURL:sourceApplication:annotation:].

 @return YES if the URL was intended for the Facebook SDK, NO if not.
 */
- (BOOL)application:(UIApplication *)application
            openURL:(NSURL *)url
  sourceApplication:(nullable NSString *)sourceApplication
         annotation:(nullable id)annotation;

/**
 Call this method from the [UIApplicationDelegate application:openURL:options:] method
 of the AppDelegate for your app. It should be invoked for the proper processing of responses during interaction
 with the native Facebook app or Safari as part of SSO authorization flow or Facebook dialogs.

 @param application The application as passed to [UIApplicationDelegate application:openURL:options:].

 @param url The URL as passed to [UIApplicationDelegate application:openURL:options:].

 @param options The options dictionary as passed to [UIApplicationDelegate application:openURL:options:].

 @return YES if the URL was intended for the Facebook SDK, NO if not.
 */
- (BOOL)application:(UIApplication *)application
            openURL:(NSURL *)url
            options:(NSDictionary<UIApplicationOpenURLOptionsKey, id> *)options;

/**
 Call this method from the [UIApplicationDelegate application:didFinishLaunchingWithOptions:] method
 of the AppDelegate for your app. It should be invoked for the proper use of the Facebook SDK.
 As part of SDK initialization basic auto logging of app events will occur, this can be
 controlled via 'FacebookAutoLogAppEventsEnabled' key in the project info plist file.

 @param application The application as passed to [UIApplicationDelegate application:didFinishLaunchingWithOptions:].

 @param launchOptions The launchOptions as passed to [UIApplicationDelegate application:didFinishLaunchingWithOptions:].

 @return True if there are any added application observers that themselves return true from calling `application:didFinishLaunchingWithOptions:`.
   Otherwise will return false. Note: If this method is called after calling `initializeSDK` then the return type will always be false.
 */
- (BOOL)            application:(UIApplication *)application
  didFinishLaunchingWithOptions:(nullable NSDictionary<UIApplicationLaunchOptionsKey, id> *)launchOptions;

/**
 Initializes the SDK.

 If you are using the SDK within the context of the UIApplication lifecycle, do not use this method.
 Instead use `application: didFinishLaunchingWithOptions:`.

 As part of SDK initialization basic auto logging of app events will occur, this can be
 controlled via 'FacebookAutoLogAppEventsEnabled' key in the project info plist file.
 */
- (void)initializeSDK;

/**
 Adds an observer that will be informed about application lifecycle events.

 @note Observers are weakly held
 */
- (void)addObserver:(id<FBSDKApplicationObserving>)observer;

/**
 Removes an observer so that it will no longer be informed about application lifecycle events.

 @note Observers are weakly held
 */
- (void)removeObserver:(id<FBSDKApplicationObserving>)observer;

@end

NS_ASSUME_NONNULL_END
