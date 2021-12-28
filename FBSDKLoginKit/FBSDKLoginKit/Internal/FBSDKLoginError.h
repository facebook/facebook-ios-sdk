/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !TARGET_OS_TV

#import <Foundation/Foundation.h>

#import <FBSDKLoginKit/FBSDKLoginConstants.h>

NS_ASSUME_NONNULL_BEGIN

@interface FBSDKLoginErrorFactory : NSObject

+ (NSError *)fbErrorForFailedLoginWithCode:(FBSDKLoginError)code;
+ (NSError *)fbErrorForSystemPasswordChange:(NSError *)innerError;

+ (nullable NSError *)fbErrorFromReturnURLParameters:(NSDictionary<NSString *, id> *)parameters;
+ (nullable NSError *)fbErrorFromServerError:(NSError *)serverError;

@end

NS_ASSUME_NONNULL_END

#endif
