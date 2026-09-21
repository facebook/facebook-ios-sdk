/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !TARGET_OS_TV

#import "FBSDKBridgeAPIResponse.h"

#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import <FBSDKCoreKit_Basics/FBSDKCoreKit_Basics.h>

#import "FBSDKBridgeAPIRequest+Private.h"
#import "FBSDKConstants.h"
#import "FBSDKInternalUtility+Internal.h"

@interface FBSDKBridgeAPIResponse ()
- (instancetype)initWithRequest:(id<FBSDKBridgeAPIRequest>)request
             responseParameters:(NSDictionary<NSString *, id> *)responseParameters
                      cancelled:(BOOL)cancelled
                          error:(NSError *)error
  NS_DESIGNATED_INITIALIZER;
@end

@implementation FBSDKBridgeAPIResponse

#pragma mark - Class Methods

+ (instancetype)bridgeAPIResponseWithRequest:(id<FBSDKBridgeAPIRequest>)request
                                       error:(nullable NSError *)error
{
  return [[self alloc] initWithRequest:request
                    responseParameters:nil
                             cancelled:NO
                                 error:error];
}

+ (nullable instancetype)bridgeAPIResponseWithRequest:(NSObject<FBSDKBridgeAPIRequest> *)request
                                          responseURL:(NSURL *)responseURL
                                    sourceApplication:(nullable NSString *)sourceApplication
                                                error:(NSError *__autoreleasing *)errorRef
{
  // `sourceApplication` is unused: iOS stopped supplying it to the bridge callback
  // in iOS 13, so it cannot be validated. The parameter is kept for API compatibility.
  NSDictionary<NSString *, NSString *> *const queryParameters = [FBSDKBasicUtility dictionaryWithQueryString:responseURL.query];
  id<FBSDKBridgeAPIProtocol> protocol = request.protocol;
  BOOL cancelled = NO;
  NSError *error = nil;
  NSDictionary<NSString *, id> *responseParameters = [protocol responseParametersForActionID:request.actionID
                                                                             queryParameters:queryParameters
                                                                                   cancelled:&cancelled
                                                                                       error:&error];
  if (errorRef != NULL) {
    *errorRef = error;
  }
  if (!responseParameters) {
    if (errorRef != NULL) {
      *errorRef = [[NSError alloc] initWithDomain:FBSDKErrorDomain code:FBSDKErrorBridgeAPIResponse userInfo:nil];
    }
    return nil;
  }
  return [[self alloc] initWithRequest:request
                    responseParameters:responseParameters
                             cancelled:cancelled
                                 error:error];
}

+ (instancetype)bridgeAPIResponseCancelledWithRequest:(NSObject<FBSDKBridgeAPIRequest> *)request
{
  return [[self alloc] initWithRequest:request
                    responseParameters:nil
                             cancelled:YES
                                 error:nil];
}

#pragma mark - Object Lifecycle

- (instancetype)initWithRequest:(NSObject<FBSDKBridgeAPIRequest> *)request
             responseParameters:(NSDictionary<NSString *, id> *)responseParameters
                      cancelled:(BOOL)cancelled
                          error:(nullable NSError *)error
{
  if ((self = [super init])) {
    _request = [request copy];
    _responseParameters = [responseParameters copy];
    _cancelled = cancelled;
    _error = [error copy];
  }
  return self;
}

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone
{
  return self;
}

@end

#endif
