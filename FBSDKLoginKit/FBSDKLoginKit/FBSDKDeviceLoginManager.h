/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <Foundation/Foundation.h>

#import <FBSDKLoginKit/FBSDKDeviceLoginCodeInfo.h>
#import <FBSDKLoginKit/FBSDKDeviceLoginManagerResult.h>

NS_ASSUME_NONNULL_BEGIN

@class FBSDKDeviceLoginManager;

/*!
 @abstract A delegate for `FBSDKDeviceLoginManager`.
 */
NS_SWIFT_NAME(DeviceLoginManagerDelegate)
@protocol FBSDKDeviceLoginManagerDelegate <NSObject>

/*!
 @abstract Indicates the device login flow has started. You should parse `codeInfo` to
  present the code to the user to enter.
 @param loginManager the login manager instance.
 @param codeInfo the code info data.
 */
- (void)deviceLoginManager:(FBSDKDeviceLoginManager *)loginManager
       startedWithCodeInfo:(FBSDKDeviceLoginCodeInfo *)codeInfo;

/*!
 @abstract Indicates the device login flow has finished.
 @param loginManager the login manager instance.
 @param result the results of the login flow.
 @param error the error, if available.
 @discussion The flow can be finished if the user completed the flow, cancelled, or if the code has expired.
 */
- (void)deviceLoginManager:(FBSDKDeviceLoginManager *)loginManager
       completedWithResult:(nullable FBSDKDeviceLoginManagerResult *)result
                     error:(nullable NSError *)error;

@end

/*!
 @abstract Use this class to perform a device login flow.
 @discussion The device login flow starts by requesting a code from the device login API.
   This class informs the delegate when this code is received. You should then present the
   code to the user to enter. In the meantime, this class polls the device login API
   periodically and informs the delegate of the results.

 See [Facebook Device Login](https://developers.facebook.com/docs/facebook-login/for-devices).
 */
NS_SWIFT_NAME(DeviceLoginManager)
@interface FBSDKDeviceLoginManager : NSObject <NSNetServiceDelegate>

/*!
 @abstract Initializes a new instance.
 @param permissions permissions to request.
 */
- (instancetype)initWithPermissions:(NSArray<NSString *> *)permissions
                   enableSmartLogin:(BOOL)enableSmartLogin
  NS_DESIGNATED_INITIALIZER;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

/*!
 @abstract the delegate.
 */
@property (nonatomic, weak) id<FBSDKDeviceLoginManagerDelegate> delegate;

/*!
 @abstract the requested permissions.
 */
@property (nonatomic, readonly, copy) NSArray<NSString *> *permissions;

/*!
 @abstract the optional URL to redirect the user to after they complete the login.
 @discussion the URL must be configured in your App Settings -> Advanced -> OAuth Redirect URIs
 */
@property (nullable, nonatomic, copy) NSURL *redirectURL;

/*!
 @abstract Starts the device login flow
 @discussion This instance will retain self until the flow is finished or cancelled.
 */
- (void)start;

/*!
 @abstract Attempts to cancel the device login flow.
 */
- (void)cancel;

@end

NS_ASSUME_NONNULL_END
