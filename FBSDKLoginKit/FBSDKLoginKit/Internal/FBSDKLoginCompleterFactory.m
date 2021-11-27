/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !TARGET_OS_TV

#import "FBSDKLoginCompleterFactory.h"

#import <Foundation/Foundation.h>

#import "FBSDKLoginURLCompleter.h"

NS_ASSUME_NONNULL_BEGIN

@implementation FBSDKLoginCompleterFactory

- (id<FBSDKLoginCompleting>)createLoginCompleterWithURLParameters:(NSDictionary<NSString *, id> *)parameters
                                                            appID:(NSString *)appID
                                    graphRequestConnectionFactory:(id<FBSDKGraphRequestConnectionFactory>)graphRequestConnectionFactory
                                       authenticationTokenCreator:(id<FBSDKAuthenticationTokenCreating>)authenticationTokenCreator
{
  return [[FBSDKLoginURLCompleter alloc] initWithURLParameters:parameters
                                                         appID:appID
                                 graphRequestConnectionFactory:graphRequestConnectionFactory
                                    authenticationTokenCreator:authenticationTokenCreator];
}

@end

NS_ASSUME_NONNULL_END

#endif
