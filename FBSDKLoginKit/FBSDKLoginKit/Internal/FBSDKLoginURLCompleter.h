/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !TARGET_OS_TV

#import <Foundation/Foundation.h>

#import <FBSDKCoreKit/FBSDKGraphRequestConnectionFactory.h>

#import "FBSDKAuthenticationTokenCreating.h"
#import "FBSDKLoginCompleting.h"

NS_ASSUME_NONNULL_BEGIN

/**
  Extracts the log in completion parameters from the \p parameters dictionary,
 which must contain the parsed result of the return URL query string.

 The \c user_id key is first used to derive the User ID. If that fails, \c signed_request
 is used.

 Completion occurs synchronously.
 */
NS_SWIFT_NAME(LoginURLCompleter)
@interface FBSDKLoginURLCompleter : NSObject <FBSDKLoginCompleting>

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

- (instancetype)initWithURLParameters:(NSDictionary<NSString *, id> *)parameters
                                appID:(NSString *)appID
        graphRequestConnectionFactory:(id<FBSDKGraphRequestConnectionFactory>)graphRequestConnectionFactory
           authenticationTokenCreator:(id<FBSDKAuthenticationTokenCreating>)authenticationTokenCreator;

@end

NS_ASSUME_NONNULL_END

#endif
