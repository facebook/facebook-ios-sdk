/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "FBSDKErrorFactory.h"

#import "FBSDKConstants.h"

NS_ASSUME_NONNULL_BEGIN

@implementation FBSDKErrorFactory

// MARK: - Lifecycle

- (instancetype)initWithReporter:(id<FBSDKErrorReporting>)reporter
{
  if ((self = [super init])) {
    _reporter = reporter;
  }

  return self;
}

// MARK: - General Errors

- (NSError *)errorWithCode:(NSInteger)code
                  userInfo:(nullable NSDictionary<NSErrorUserInfoKey, id> *)userInfo
                   message:(nullable NSString *)message
           underlyingError:(nullable NSError *)underlyingError
{
  return [self errorWithDomain:FBSDKErrorDomain
                          code:code
                      userInfo:userInfo
                       message:message
               underlyingError:underlyingError];
}

- (NSError *)errorWithDomain:(NSErrorDomain)domain
                        code:(NSInteger)code
                    userInfo:(nullable NSDictionary<NSErrorUserInfoKey, id> *)userInfo
                     message:(nullable NSString *)message
             underlyingError:(nullable NSError *)underlyingError
{
  NSMutableDictionary<NSString *, id> *fullUserInfo = [[NSMutableDictionary alloc] initWithDictionary:userInfo];

  if (message) {
    fullUserInfo[FBSDKErrorDeveloperMessageKey] = message;
  }

  if (underlyingError) {
    fullUserInfo[NSUnderlyingErrorKey] = underlyingError;
  }

  userInfo = fullUserInfo.count ? [fullUserInfo copy] : nil;
  [self.reporter saveError:code errorDomain:domain message:message];

  return [[NSError alloc] initWithDomain:domain code:code userInfo:userInfo];
}

@end

NS_ASSUME_NONNULL_END
