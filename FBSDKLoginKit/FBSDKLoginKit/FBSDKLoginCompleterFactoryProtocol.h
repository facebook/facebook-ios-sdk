/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !TARGET_OS_TV

#import <Foundation/Foundation.h>

#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import <FBSDKLoginKit/FBSDKLoginCompleting.h>

#import "FBSDKAuthenticationTokenCreating.h"

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(LoginCompleterFactoryProtocol)
@protocol FBSDKLoginCompleterFactory

// UNCRUSTIFY_FORMAT_OFF
- (id<FBSDKLoginCompleting>)createLoginCompleterWithURLParameters:(NSDictionary<NSString *, id> *)parameters
                                                            appID:(NSString *)appID
                                       authenticationTokenCreator:(id<FBSDKAuthenticationTokenCreating>)authenticationTokenCreator
                                              graphRequestFactory:(id<FBSDKGraphRequestFactory>)graphRequestFactory
                                                  internalUtility:(id<FBSDKURLHosting>)internalUtility
  NS_SWIFT_NAME(createLoginCompleter(urlParameters:appID:authenticationTokenCreator:graphRequestFactory:internalUtility:));
// UNCRUSTIFY_FORMAT_ON

@end

NS_ASSUME_NONNULL_END

#endif
