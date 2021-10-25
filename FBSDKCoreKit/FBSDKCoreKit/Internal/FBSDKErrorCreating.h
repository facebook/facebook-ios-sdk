/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(SDKErrorCreating)
@protocol FBSDKErrorCreating

// MARK: - General Errors

- (NSError *)errorWithCode:(NSInteger)code
                  userInfo:(nullable NSDictionary<NSErrorUserInfoKey, id> *)userInfo
                   message:(nullable NSString *)message
           underlyingError:(nullable NSError *)underlyingError
NS_SWIFT_NAME(error(code:userInfo:message:underlyingError:));

- (NSError *)errorWithDomain:(NSErrorDomain)domain
                        code:(NSInteger)code
                    userInfo:(nullable NSDictionary<NSErrorUserInfoKey, id> *)userInfo
                     message:(nullable NSString *)message
             underlyingError:(nullable NSError *)underlyingError
NS_SWIFT_NAME(error(domain:code:userInfo:message:underlyingError:));

@end

NS_ASSUME_NONNULL_END
