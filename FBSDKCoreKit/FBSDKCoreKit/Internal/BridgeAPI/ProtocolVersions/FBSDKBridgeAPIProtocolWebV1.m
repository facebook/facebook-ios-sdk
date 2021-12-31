/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
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

#import "FBSDKErrorFactory+Internal.h"
#import "FBSDKErrorReporter.h"
#import "FBSDKInternalUtility+Internal.h"

#define FBSDK_BRIDGE_API_PROTOCOL_WEB_V1_ACTION_ID_KEY @"action_id"
#define FBSDK_BRIDGE_API_PROTOCOL_WEB_V1_BRIDGE_ARGS_KEY @"bridge_args"

@implementation FBSDKBridgeAPIProtocolWebV1

// MARK: - Object Lifecycle

- (instancetype)init
{
  FBSDKErrorFactory *factory = [[FBSDKErrorFactory alloc] initWithReporter:FBSDKErrorReporter.shared];
  return [self initWithErrorFactory:factory internalUtility:FBSDKInternalUtility.sharedUtility];
}

- (instancetype)initWithErrorFactory:(nonnull id<FBSDKErrorCreating>)errorFactory
                     internalUtility:(nonnull id<FBSDKInternalUtility>)internalUtility
{
  if ((self = [super init])) {
    _errorFactory = errorFactory;
    _internalUtility = internalUtility;
  }

  return self;
}

// MARK: - FBSDKBridgeAPIProtocol

- (nullable NSURL *)requestURLWithActionID:(NSString *)actionID
                                    scheme:(NSString *)scheme
                                methodName:(NSString *)methodName
                                parameters:(NSDictionary<NSString *, NSString *> *)parameters
                                     error:(NSError *__autoreleasing *)errorRef
{
  if (![FBSDKTypeUtility coercedToStringValue:actionID] || ![FBSDKTypeUtility coercedToStringValue:methodName]) {
    return nil;
  }

  NSString *bridgeArgumentsJSONString = [FBSDKBasicUtility JSONStringForObject:@{ FBSDK_BRIDGE_API_PROTOCOL_WEB_V1_ACTION_ID_KEY : actionID }
                                                                         error:NULL
                                                          invalidObjectHandler:NULL];
  NSDictionary<NSString *, NSString *> *redirectQueryParameters = @{
    FBSDK_BRIDGE_API_PROTOCOL_WEB_V1_BRIDGE_ARGS_KEY : bridgeArgumentsJSONString
  };
  NSURL *redirectURL = [self.internalUtility appURLWithHost:@"bridge"
                                                       path:methodName
                                            queryParameters:redirectQueryParameters
                                                      error:NULL];

  NSMutableDictionary<NSString *, NSString *> *queryParameters = [[NSMutableDictionary alloc] initWithDictionary:parameters];
  [FBSDKTypeUtility dictionary:queryParameters setObject:@"touch" forKey:@"display"];
  [FBSDKTypeUtility dictionary:queryParameters setObject:redirectURL.absoluteString forKey:@"redirect_uri"];
  [queryParameters addEntriesFromDictionary:parameters]; // this could overwrite values we just added

  return [self.internalUtility facebookURLWithHostPrefix:@"m"
                                                    path:[@"/dialog/" stringByAppendingString:methodName]
                                         queryParameters:queryParameters
                                                   error:NULL];
}

- (nullable NSDictionary<NSString *, id> *)responseParametersForActionID:(NSString *)actionID
                                                         queryParameters:(NSDictionary<NSString *, NSString *> *)queryParameters
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
