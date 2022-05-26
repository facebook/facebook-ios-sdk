/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !TARGET_OS_TV

#import <Foundation/Foundation.h>

#import <FBSDKCoreKit/FBSDKGraphRequestConnectionFactory.h>
#import <FBSDKLoginKit/FBSDKLoginCompleting.h>

#import "FBSDKAuthenticationTokenCreating.h"

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

@property (nonatomic) id<NSObject> observer;
@property (nonatomic) BOOL performExplicitFallback;
@property (nonatomic) id<FBSDKAuthenticationTokenCreating> authenticationTokenCreator;
@property (nonatomic) FBSDKLoginCompletionParameters *parameters;
@property (nonatomic) id<FBSDKGraphRequestFactory> graphRequestFactory;
@property (nonatomic) id<FBSDKURLHosting> internalUtility;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

- (instancetype)initWithURLParameters:(NSDictionary<NSString *, id> *)parameters
                                appID:(NSString *)appID
           authenticationTokenCreator:(id<FBSDKAuthenticationTokenCreating>)authenticationTokenCreator
                  graphRequestFactory:(id<FBSDKGraphRequestFactory>)graphRequestFactory
                      internalUtility:(id<FBSDKURLHosting>)internalUtility;

@end

NS_ASSUME_NONNULL_END

#endif
