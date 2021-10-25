/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <Foundation/Foundation.h>

#import "FBSDKError.h"

@protocol FBSDKErrorReporting;

NS_ASSUME_NONNULL_BEGIN

@interface FBSDKError (Internal)

+ (void)configureWithErrorReporter:(id<FBSDKErrorReporting>)errorReporter;

+ (NSError *)errorWithCode:(NSInteger)code
                  userInfo:(nullable NSDictionary<NSErrorUserInfoKey, id> *)userInfo
                   message:(nullable NSString *)message
           underlyingError:(nullable NSError *)underlyingError;

+ (NSError *)invalidArgumentErrorWithName:(NSString *)name
                                    value:(nullable id)value
                                  message:(nullable NSString *)message
                          underlyingError:(nullable NSError *)underlyingError;

+ (NSError *)requiredArgumentErrorWithName:(NSString *)name message:(nullable NSString *)message;

+ (NSError *)requiredArgumentErrorWithName:(NSString *)name
                                   message:(nullable NSString *)message
                           underlyingError:(nullable NSError *)underlyingError;

@end

NS_ASSUME_NONNULL_END
