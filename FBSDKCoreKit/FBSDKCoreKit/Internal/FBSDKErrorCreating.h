/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(ErrorCreating)
@protocol FBSDKErrorCreating

// MARK: - General Errors

// UNCRUSTIFY_FORMAT_OFF
- (NSError *)errorWithCode:(NSInteger)code
                  userInfo:(nullable NSDictionary<NSErrorUserInfoKey, id> *)userInfo
                   message:(nullable NSString *)message
           underlyingError:(nullable NSError *)underlyingError
NS_SWIFT_NAME(error(code:userInfo:message:underlyingError:));
// UNCRUSTIFY_FORMAT_ON

// UNCRUSTIFY_FORMAT_OFF
- (NSError *)errorWithDomain:(NSErrorDomain)domain
                        code:(NSInteger)code
                    userInfo:(nullable NSDictionary<NSErrorUserInfoKey, id> *)userInfo
                     message:(nullable NSString *)message
             underlyingError:(nullable NSError *)underlyingError
NS_SWIFT_NAME(error(domain:code:userInfo:message:underlyingError:));
// UNCRUSTIFY_FORMAT_ON

// MARK: - Invalid Argument Errors

// UNCRUSTIFY_FORMAT_OFF
- (NSError *)invalidArgumentErrorWithName:(NSString *)name
                                    value:(nullable id)value
                                  message:(nullable NSString *)message
                          underlyingError:(nullable NSError *)underlyingError
NS_SWIFT_NAME(invalidArgumentError(name:value:message:underlyingError:));
// UNCRUSTIFY_FORMAT_ON

// UNCRUSTIFY_FORMAT_OFF
- (NSError *)invalidArgumentErrorWithDomain:(NSErrorDomain)domain
                                       name:(NSString *)name
                                      value:(nullable id)value
                                    message:(nullable NSString *)message
                            underlyingError:(nullable NSError *)underlyingError
NS_SWIFT_NAME(invalidArgumentError(domain:name:value:message:underlyingError:));
// UNCRUSTIFY_FORMAT_ON

// MARK: - Required Argument Errors

// UNCRUSTIFY_FORMAT_OFF
- (NSError *)requiredArgumentErrorWithName:(NSString *)name
                                   message:(nullable NSString *)message
                           underlyingError:(nullable NSError *)underlyingError
NS_SWIFT_NAME(requiredArgumentError(name:message:underlyingError:));
// UNCRUSTIFY_FORMAT_ON

// UNCRUSTIFY_FORMAT_OFF
- (NSError *)requiredArgumentErrorWithDomain:(NSErrorDomain)domain
                                        name:(NSString *)name
                                     message:(nullable NSString *)message
                             underlyingError:(nullable NSError *)underlyingError
  NS_SWIFT_NAME(requiredArgumentError(domain:name:message:underlyingError:));
// UNCRUSTIFY_FORMAT_ON

// MARK: - Unknown Errors

// UNCRUSTIFY_FORMAT_OFF
- (NSError *)unknownErrorWithMessage:(nullable NSString *)message
                            userInfo:(nullable NSDictionary<NSErrorUserInfoKey, id> *)userInfo
NS_SWIFT_NAME(unknownError(message:userInfo:));
// UNCRUSTIFY_FORMAT_ON

@end

NS_ASSUME_NONNULL_END
