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

/// The login experience style to use for a login attempt
typedef NS_ENUM(NSUInteger, FBSDKBetaLoginExperience)
{
  FBSDKBetaLoginExperienceEnabled,
  FBSDKBetaLoginExperienceRestricted,
} NS_SWIFT_NAME(BetaLoginExperience);

/// A configuration to use for modifying the default behavior of a login attempt.
NS_SWIFT_NAME(LoginConfiguration)
@interface FBSDKLoginConfiguration : NSObject

/// The nonce that the configuration was created with.
/// A unique nonce will be used if none is provided to the initializer.
@property (nonatomic, readonly, copy) NSString *nonce;

/// The beta login experience preference. Defaults to `.enabled`.
@property (nonatomic, readonly) FBSDKBetaLoginExperience betaLoginExperience;

/// The requested permissions for the login attempt. Defaults to an empty set.
@property (nonatomic, readonly, copy) NSSet<NSString *> *requestedPermissions;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

/**
 Attempts to initialize a new configuration with the expected parameters.

 @param permissions the requested permissions for the login attempt. Permissions must be an array of strings that do not contain whitespace.
 The only permissions allowed when the `betaLoginExperience` is `.restricted` are 'email' and 'public_profile'.
 @param betaLoginExperience determines whether the login attempt should use the beta experience.
 @param nonce an optional nonce to use for the login attempt. A valid nonce must be a non-empty string without whitespace.
 Creation of the configuration will fail if the nonce is invalid.
 */
- (nullable instancetype)initWithPermissions:(NSArray<NSString *> *)permissions
                         betaLoginExperience:(FBSDKBetaLoginExperience)betaLoginExperience
                                       nonce:(NSString *)nonce
NS_REFINED_FOR_SWIFT;

/**
 Attempts to initialize a new configuration with the expected parameters.

 @param permissions the requested permissions for the login attempt. Permissions must be an array of strings that do not contain whitespace.
  The only permissions allowed when the `betaLoginExperience` is `.restricted` are 'email' and 'public_profile'.
 @param betaLoginExperience determines whether the login attempt should use the beta experience.
 */
- (nullable instancetype)initWithPermissions:(NSArray<NSString *> *)permissions
                         betaLoginExperience:(FBSDKBetaLoginExperience)betaLoginExperience
NS_REFINED_FOR_SWIFT;

/**
 Attempts to initialize a new configuration with the expected parameters.

 @param betaLoginExperience determines whether the login attempt should use the beta experience.
 */
- (nullable instancetype)initWithBetaLoginExperience:(FBSDKBetaLoginExperience)betaLoginExperience
NS_REFINED_FOR_SWIFT;

@end

NS_ASSUME_NONNULL_END
