/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <UIKit/UIKit.h>

#import <FBSDKLoginKit/FBSDKDefaultAudience.h>
#import <FBSDKLoginKit/FBSDKLoginManagerLoginResultBlock.h>
#import <FBSDKLoginKit/FBSDKLoginProviding.h>

NS_ASSUME_NONNULL_BEGIN

#if !TARGET_OS_TV

@class FBSDKLoginConfiguration;
@class FBSDKPermission;

/**
 `FBSDKLoginManager` provides methods for logging the user in and out.

 `FBSDKLoginManager` serves to help manage sessions represented by tokens for authentication,
 `AuthenticationToken`, and data access, `AccessToken`.

 You should check if the type of token you expect is present as a singleton instance, either `AccessToken.current`
 or `AuthenticationToken.current` before calling any of the login methods to see if there is a cached token
 available. A standard place to do this is in `viewDidLoad`.

 @warning If you are managing your own token instances outside of `AccessToken.current`, you will need to set
 `AccessToken.current` before calling any of the login methods to authorize further permissions on your tokens.
 */
NS_SWIFT_NAME(LoginManager)
@interface FBSDKLoginManager : NSObject <FBSDKLoginProviding>

/**
 Internal property exposed to facilitate transition to Swift.
 API Subject to change or removal without warning. Do not use.

 @warning INTERNAL - DO NOT USE
 */
@property (nullable, nonatomic, readonly) NSSet<FBSDKPermission *> *requestedPermissions;

/**
 the default audience.

 you should set this if you intend to ask for publish permissions.
 */
@property (nonatomic, assign) FBSDKDefaultAudience defaultAudience;

/**
 Logs the user in or authorizes additional permissions.

 @param permissions the optional array of permissions. Note this is converted to NSSet and is only
 an NSArray for the convenience of literal syntax.
 @param fromViewController the view controller to present from. If nil, the topmost view controller will be
 automatically determined as best as possible.
 @param handler the callback.

 Use this method when asking for read permissions. You should only ask for permissions when they
 are needed and explain the value to the user. You can inspect the `FBSDKLoginManagerLoginResultBlock`'s
 `result.declinedPermissions` to provide more information to the user if they decline permissions.
 You typically should check if `AccessToken.current` already contains the permissions you need before
 asking to reduce unnecessary login attempts. For example, you could perform that check in `viewDidLoad`.

 @warning You can only perform one login call at a time. Calling a login method before the completion handler is called
 on a previous login attempt will result in an error.
 @warning This method will present a UI to the user and thus should be called on the main thread.
 */

// UNCRUSTIFY_FORMAT_OFF
- (void)logInWithPermissions:(NSArray<NSString *> *)permissions
          fromViewController:(nullable UIViewController *)fromViewController
                     handler:(nullable FBSDKLoginManagerLoginResultBlock)handler
NS_SWIFT_NAME(logIn(permissions:from:handler:));
// UNCRUSTIFY_FORMAT_ON

/**
 Logs the user in or authorizes additional permissions.

 @param viewController the view controller from which to present the login UI. If nil, the topmost view
 controller will be automatically determined and used.
 @param configuration the login configuration to use.
 @param completion the login completion handler.

 Use this method when asking for permissions. You should only ask for permissions when they
 are needed and the value should be explained to the user. You can inspect the
 `FBSDKLoginManagerLoginResultBlock`'s `result.declinedPermissions` to provide more information
 to the user if they decline permissions.
 To reduce unnecessary login attempts, you should typically check if `AccessToken.current`
 already contains the permissions you need. If it does, you probably do not need to call this method.

 @warning You can only perform one login call at a time. Calling a login method before the completion handler is called
 on a previous login attempt will result in an error.
 @warning This method will present a UI to the user and thus should be called on the main thread.
 */
- (void)logInFromViewController:(nullable UIViewController *)viewController
                  configuration:(FBSDKLoginConfiguration *)configuration
                     completion:(FBSDKLoginManagerLoginResultBlock)completion
  NS_REFINED_FOR_SWIFT;

/**
 Requests user's permission to reathorize application's data access, after it has expired due to inactivity.
 @param fromViewController the view controller from which to present the login UI. If nil, the topmost view
 controller will be automatically determined and used.
 @param handler the callback.

Use this method when you need to reathorize your app's access to user data via the Graph API.
You should only call this after access has expired.
You should provide as much context to the user as possible as to why you need to reauthorize the access, the
scope of access being reathorized, and what added value your app provides when the access is reathorized.
You can inspect the `result.declinedPermissions` to determine if you should provide more information to the
user based on any declined permissions.

 @warning This method will reauthorize using a `LoginConfiguration` with `FBSDKLoginTracking` set to `.enabled`.
 @warning This method will present UI the user. You typically should call this if `AccessToken.isDataAccessExpired` is true.
 */

// UNCRUSTIFY_FORMAT_OFF
- (void)reauthorizeDataAccess:(UIViewController *)fromViewController
                      handler:(FBSDKLoginManagerLoginResultBlock)handler
NS_SWIFT_NAME(reauthorizeDataAccess(from:handler:));
// UNCRUSTIFY_FORMAT_ON

/**
 Logs the user out

 This nils out the singleton instances of `AccessToken` `AuthenticationToken` and `Profle`.

 @note This is only a client side logout. It will not log the user out of their Facebook account.
 */
- (void)logOut;

@end

#endif

NS_ASSUME_NONNULL_END
