/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !TARGET_OS_TV

#import "FBSDKBridgeAPIProtocolWebV1.h"

#import <UIKit/UIKit.h>

#import <FBSDKCoreKit/FBSDKConstants.h>
#import <FBSDKCoreKit_Basics/FBSDKCoreKit_Basics.h>

#import "FBSDKErrorCreating.h"
#import "FBSDKErrorFactory.h"
#import "FBSDKErrorReporter.h"
#import "FBSDKInternalUtility+Internal.h"

#define FBSDK_BRIDGE_API_PROTOCOL_WEB_V1_ACTION_ID_KEY @"action_id"
#define FBSDK_BRIDGE_API_PROTOCOL_WEB_V1_BRIDGE_ARGS_KEY @"bridge_args"

@implementation FBSDKBridgeAPIProtocolWebV1

// MARK: - Object Lifecycle

- (instancetype)init
{
  FBSDKErrorFactory *factory = [[FBSDKErrorFactory alloc] initWithReporter:FBSDKErrorReporter.shared];
  return [self initWithErrorFactory:factory];
}

- (instancetype)initWithErrorFactory:(id<FBSDKErrorCreating>)errorFactory
{
  if ((self = [super init])) {
    _errorFactory = errorFactory;
  }

  return self;
}

// MARK: - FBSDKBridgeAPIProtocol

- (nullable NSURL *)requestURLWithActionID:(NSString *)actionID
                                    scheme:(NSString *)scheme
                                methodName:(NSString *)methodName
                                parameters:(NSDictionary<NSString *, id> *)parameters
                                     error:(NSError *__autoreleasing *)errorRef
{
  if (![FBSDKTypeUtility coercedToStringValue:actionID] || ![FBSDKTypeUtility coercedToStringValue:methodName]) {
    return nil;
  }
  NSMutableDictionary<NSString *, id> *queryParameters = [[NSMutableDictionary alloc] initWithDictionary:parameters];
  [FBSDKTypeUtility dictionary:queryParameters setObject:@"touch" forKey:@"display"];
  NSString *bridgeArgs = [FBSDKBasicUtility JSONStringForObject:@{ FBSDK_BRIDGE_API_PROTOCOL_WEB_V1_ACTION_ID_KEY : actionID }
                                                          error:NULL
                                           invalidObjectHandler:NULL];
  NSDictionary<NSString *, id> *redirectQueryParameters = @{ FBSDK_BRIDGE_API_PROTOCOL_WEB_V1_BRIDGE_ARGS_KEY : bridgeArgs };
  NSURL *redirectURL = [FBSDKInternalUtility.sharedUtility appURLWithHost:@"bridge"
                                                                     path:methodName
                                                          queryParameters:redirectQueryParameters
                                                                    error:NULL];
  [FBSDKTypeUtility dictionary:queryParameters setObject:redirectURL forKey:@"redirect_uri"];
  [queryParameters addEntriesFromDictionary:parameters];
  return [FBSDKInternalUtility.sharedUtility facebookURLWithHostPrefix:@"m"
                                                                  path:[@"/dialog/" stringByAppendingString:methodName]
                                                       queryParameters:queryParameters
                                                                 error:NULL];
}

- (nullable NSDictionary<NSString *, id> *)responseParametersForActionID:(NSString *)actionID
                                                         queryParameters:(NSDictionary<NSString *, id> *)queryParameters
                                                               cancelled:(BOOL *)cancelledRef
                                                                   error:(NSError *__autoreleasing *)errorRef
{
  if (errorRef != NULL) {
    *errorRef = nil;
  }
  NSInteger errorCode = [FBSDKTypeUtility integerValue:queryParameters[@"error_code"]];
  switch (errorCode) {
    case 0: {
      // good to go, handle the other codes and bail
      break;
    }
    case 4201: {
      return @{
        @"completionGesture" : @"cancel",
      };
    }
    default: {
      if (errorRef != NULL) {
        NSString *message = [FBSDKTypeUtility coercedToStringValue:queryParameters[@"error_message"]];
        *errorRef = [self.errorFactory errorWithCode:errorCode
                                            userInfo:nil
                                             message:message
                                     underlyingError:nil];
      }
      return nil;
    }
  }

  NSError *error;
  NSString *bridgeParametersJSON = [FBSDKTypeUtility coercedToStringValue:queryParameters[FBSDK_BRIDGE_API_PROTOCOL_WEB_V1_BRIDGE_ARGS_KEY]];
  NSDictionary<id, id> *bridgeParameters = [FBSDKBasicUtility objectForJSONString:bridgeParametersJSON error:&error];
  if (!bridgeParameters) {
    if (error && (errorRef != NULL)) {
      *errorRef = [self.errorFactory invalidArgumentErrorWithName:FBSDK_BRIDGE_API_PROTOCOL_WEB_V1_BRIDGE_ARGS_KEY
                                                            value:bridgeParametersJSON
                                                          message:nil
                                                  underlyingError:error];
    }
    return nil;
  }
  NSString *responseActionID = bridgeParameters[FBSDK_BRIDGE_API_PROTOCOL_WEB_V1_ACTION_ID_KEY];
  responseActionID = [FBSDKTypeUtility coercedToStringValue:responseActionID];
  if (![responseActionID isEqualToString:actionID]) {
    return nil;
  }
  NSMutableDictionary<NSString *, id> *resultParameters = [queryParameters mutableCopy];
  [resultParameters removeObjectForKey:FBSDK_BRIDGE_API_PROTOCOL_WEB_V1_BRIDGE_ARGS_KEY];
  resultParameters[@"didComplete"] = @YES;
  return resultParameters;
}

@end

#endif
