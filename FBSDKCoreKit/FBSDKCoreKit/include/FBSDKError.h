/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(SDKError)
@interface FBSDKError : NSObject

+ (NSError *)errorWithCode:(NSInteger)code message:(nullable NSString *)message;

+ (NSError *)errorWithDomain:(NSErrorDomain)domain code:(NSInteger)code message:(nullable NSString *)message;

+ (NSError *)errorWithCode:(NSInteger)code
                   message:(nullable NSString *)message
           underlyingError:(nullable NSError *)underlyingError;

+ (NSError *)errorWithDomain:(NSErrorDomain)domain
                        code:(NSInteger)code
                     message:(nullable NSString *)message
             underlyingError:(nullable NSError *)underlyingError;

+ (NSError *)errorWithDomain:(NSErrorDomain)domain
                        code:(NSInteger)code
                    userInfo:(nullable NSDictionary<NSErrorUserInfoKey, id> *)userInfo
                     message:(nullable NSString *)message
             underlyingError:(nullable NSError *)underlyingError;

+ (NSError *)invalidArgumentErrorWithName:(NSString *)name
                                    value:(nullable id)value
                                  message:(nullable NSString *)message;

+ (NSError *)invalidArgumentErrorWithDomain:(NSErrorDomain)domain
                                       name:(NSString *)name
                                      value:(nullable id)value
                                    message:(nullable NSString *)message;

+ (NSError *)invalidArgumentErrorWithDomain:(NSErrorDomain)domain
                                       name:(NSString *)name
                                      value:(nullable id)value
                                    message:(nullable NSString *)message
                            underlyingError:(nullable NSError *)underlyingError;

+ (NSError *)requiredArgumentErrorWithDomain:(NSErrorDomain)domain
                                        name:(NSString *)name
                                     message:(nullable NSString *)message;

+ (NSError *)unknownErrorWithMessage:(NSString *)message;

+ (BOOL)isNetworkError:(NSError *)error;

@end

NS_ASSUME_NONNULL_END
