/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <UIKit/UIKit.h>

#import "TargetConditionals.h"

#if TARGET_OS_TV

@interface FBLoginButton : UIView

@property (nonatomic, copy) NSArray<NSString *> *permissions;

@end

#else

 #import <FBSDKCoreKit/FBSDKCoreKit.h>
 #import <FBSDKLoginKit/FBSDKLoginManager.h>
 #import <FBSDKLoginKit/FBSDKTooltipView.h>

NS_ASSUME_NONNULL_BEGIN

@protocol FBSDKLoginButtonDelegate;

/**
 NS_ENUM(NSUInteger, FBSDKLoginButtonTooltipBehavior)
  Indicates the desired login tooltip behavior.
 */
typedef NS_ENUM(NSUInteger, FBSDKLoginButtonTooltipBehavior) {
  /** The default behavior. The tooltip will only be displayed if
   the app is eligible (determined by possible server round trip) */
  FBSDKLoginButtonTooltipBehaviorAutomatic = 0,
  /** Force display of the tooltip (typically for UI testing) */
  FBSDKLoginButtonTooltipBehaviorForceDisplay = 1,
  /** Force disable. In this case you can still exert more refined
   control by manually constructing a `FBSDKLoginTooltipView` instance. */
  FBSDKLoginButtonTooltipBehaviorDisable = 2,
} NS_SWIFT_NAME(FBLoginButton.TooltipBehavior);

/**
  A button that initiates a log in or log out flow upon tapping.

 `FBSDKLoginButton` works with `FBSDKProfile.currentProfile` to
  determine what to display, and automatically starts authentication when tapped (i.e.,
  you do not need to manually subscribe action targets).

  Like `FBSDKLoginManager`, you should make sure your app delegate is connected to
  `FBSDKApplicationDelegate` in order for the button's delegate to receive messages.

 `FBSDKLoginButton` has a fixed height of @c 30 pixels, but you may change the width. `initWithFrame:CGRectZero`
 will size the button to its minimum frame.
*/
NS_SWIFT_NAME(FBLoginButton)
@interface FBSDKLoginButton : FBSDKButton

/**
  The default audience to use, if publish permissions are requested at login time.
 */
@property (nonatomic, assign) FBSDKDefaultAudience defaultAudience;
/**
  Gets or sets the delegate.
 */
@property (nonatomic, weak) IBOutlet id<FBSDKLoginButtonDelegate> delegate;
/*!
 @abstract The permissions to request.
 @discussion To provide the best experience, you should minimize the number of permissions you request, and only ask for them when needed.
 For example, do not ask for "user_location" until you the information is actually used by the app.

 Note this is converted to NSSet and is only
 an NSArray for the convenience of literal syntax.

 See [the permissions guide]( https://developers.facebook.com/docs/facebook-login/permissions/ ) for more details.
 */
@property (nonatomic, copy) NSArray<NSString *> *permissions;
/**
  Gets or sets the desired tooltip behavior.
 */
@property (nonatomic, assign) FBSDKLoginButtonTooltipBehavior tooltipBehavior;
/**
  Gets or sets the desired tooltip color style.
 */
@property (nonatomic, assign) FBSDKTooltipColorStyle tooltipColorStyle;
/**
  Gets or sets the desired tracking preference to use for login attempts. Defaults to `.enabled`
 */
@property (nonatomic, assign) FBSDKLoginTracking loginTracking;
/**
  Gets or sets an optional nonce to use for login attempts. A valid nonce must be a non-empty string without whitespace.
 An invalid nonce will not be set. Instead, default unique nonces will be used for login attempts.
 */
@property (nullable, nonatomic, copy) NSString *nonce;
/**
  Gets or sets an optional page id to use for login attempts.
 */
@property (nullable, nonatomic, copy) NSString *messengerPageId;
/**
  Gets or sets the auth_type to use in the login request. Defaults to rerequest.
 */
@property (nullable, nonatomic) FBSDKLoginAuthType authType;

@end

NS_ASSUME_NONNULL_END

#endif
