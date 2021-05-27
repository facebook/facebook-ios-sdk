// Copyright (c) 2014-present, Facebook, Inc. All rights reserved.
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

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class FBSDKPermission;

/// typedef for FBSDKLoginAuthType
/// See: https://developers.facebook.com/docs/reference/javascript/FB.login/v10.0#options
typedef NSString *const FBSDKLoginAuthType NS_TYPED_EXTENSIBLE_ENUM NS_SWIFT_NAME(LoginAuthType);

/// Rerequest
FOUNDATION_EXPORT FBSDKLoginAuthType FBSDKLoginAuthTypeRerequest;

/// Reauthorize
FOUNDATION_EXPORT FBSDKLoginAuthType FBSDKLoginAuthTypeReauthorize;

/// The login tracking preference to use for a login attempt. For more information on the differences between
/// `enabled` and `limited` see: https://developers.facebook.com/docs/facebook-login/ios/limited-login/
typedef NS_ENUM(NSUInteger, FBSDKLoginTracking)
{
  FBSDKLoginTrackingEnabled,
  FBSDKLoginTrackingLimited,
} NS_SWIFT_NAME(LoginTracking);

/// A configuration to use for modifying the behavior of a login attempt.
NS_SWIFT_NAME(LoginConfiguration)
@interface FBSDKLoginConfiguration : NSObject

/// The nonce that the configuration was created with.
/// A unique nonce will be used if none is provided to the initializer.
@property (nonatomic, readonly, copy) NSString *nonce;

/// The tracking  preference. Defaults to `.enabled`.
@property (nonatomic, readonly) FBSDKLoginTracking tracking;

/// The requested permissions for the login attempt. Defaults to an empty set.
@property (nonatomic, readonly, copy) NSSet<FBSDKPermission *> *requestedPermissions;

/// The Messenger Page Id associated with this login request.
@property (nonatomic, readonly, copy, nullable) NSString *messengerPageId;

/// The auth type associated with this login request.
@property (nonatomic, readonly, nullable) FBSDKLoginAuthType authType;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

/**
 Attempts to initialize a new configuration with the expected parameters.

 @param permissions the requested permissions for a login attempt. Permissions must be an array of strings that do not contain whitespace.
 @param tracking the tracking preference to use for a login attempt.
 @param nonce an optional nonce to use for the login attempt. A valid nonce must be a non-empty string without whitespace.
 Creation of the configuration will fail if the nonce is invalid.
 @param messengerPageId the associated page id  to use for a login attempt.
 */
- (nullable instancetype)initWithPermissions:(NSArray<NSString *> *)permissions
                                    tracking:(FBSDKLoginTracking)tracking
                                       nonce:(NSString *)nonce
                             messengerPageId:(nullable NSString *)messengerPageId
NS_REFINED_FOR_SWIFT;

/**
 Attempts to initialize a new configuration with the expected parameters.

 @param permissions the requested permissions for a login attempt. Permissions must be an array of strings that do not contain whitespace.
 @param tracking the tracking preference to use for a login attempt.
 @param nonce an optional nonce to use for the login attempt. A valid nonce must be a non-empty string without whitespace.
 Creation of the configuration will fail if the nonce is invalid. 
 @param messengerPageId the associated page id  to use for a login attempt.
 @param authType auth_type param to use for login.
 */
- (nullable instancetype)initWithPermissions:(NSArray<NSString *> *)permissions
                                    tracking:(FBSDKLoginTracking)tracking
                                       nonce:(NSString *)nonce
                             messengerPageId:(nullable NSString *)messengerPageId
                                    authType:(nullable FBSDKLoginAuthType)authType
NS_REFINED_FOR_SWIFT;

/**
 Attempts to initialize a new configuration with the expected parameters.

 @param permissions the requested permissions for a login attempt. Permissions must be an array of strings that do not contain whitespace.
 @param tracking the tracking preference to use for a login attempt.
 @param nonce an optional nonce to use for the login attempt. A valid nonce must be a non-empty string without whitespace.
 Creation of the configuration will fail if the nonce is invalid.
 */
- (nullable instancetype)initWithPermissions:(NSArray<NSString *> *)permissions
                                    tracking:(FBSDKLoginTracking)tracking
                                       nonce:(NSString *)nonce
NS_REFINED_FOR_SWIFT;

/**
 Attempts to initialize a new configuration with the expected parameters.

 @param permissions the requested permissions for the login attempt. Permissions must be an array of strings that do not contain whitespace.
 @param tracking the tracking preference to use for a login attempt.
 @param messengerPageId the associated page id  to use for a login attempt.
 */
- (nullable instancetype)initWithPermissions:(NSArray<NSString *> *)permissions
                                    tracking:(FBSDKLoginTracking)tracking
                             messengerPageId:(nullable NSString *)messengerPageId
NS_REFINED_FOR_SWIFT;

/**
 Attempts to initialize a new configuration with the expected parameters.

 @param permissions the requested permissions for the login attempt. Permissions must be an array of strings that do not contain whitespace.
 @param tracking the tracking preference to use for a login attempt.
 @param messengerPageId the associated page id  to use for a login attempt.
 @param authType auth_type param to use for login.
 */
- (nullable instancetype)initWithPermissions:(NSArray<NSString *> *)permissions
                                    tracking:(FBSDKLoginTracking)tracking
                             messengerPageId:(nullable NSString *)messengerPageId
                                    authType:(nullable FBSDKLoginAuthType)authType
NS_REFINED_FOR_SWIFT;

/**
 Attempts to initialize a new configuration with the expected parameters.

 @param permissions the requested permissions for the login attempt. Permissions must be an array of strings that do not contain whitespace.
 @param tracking the tracking preference to use for a login attempt.
 */
- (nullable instancetype)initWithPermissions:(NSArray<NSString *> *)permissions
                                    tracking:(FBSDKLoginTracking)tracking
NS_REFINED_FOR_SWIFT;

/**
 Attempts to initialize a new configuration with the expected parameters.

 @param tracking the login tracking preference to use for a login attempt.
 */
- (nullable instancetype)initWithTracking:(FBSDKLoginTracking)tracking
NS_REFINED_FOR_SWIFT;

/**
 Given a string, return the corresponding FBSDKLoginAuthType. Returns nil if the string cannot be mapped to a valid auth type

 @param rawValue the raw auth type.
 */
+ (nullable FBSDKLoginAuthType)authTypeForString:(NSString *)rawValue;

@end

NS_ASSUME_NONNULL_END
