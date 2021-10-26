/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !TARGET_OS_TV

#import "FBSDKBridgeAPIProtocolWebV2.h"

#import <FBSDKCoreKit_Basics/FBSDKCoreKit_Basics.h>

#import "FBSDKBridgeAPIProtocolNativeV1.h"
#import "FBSDKDialogConfiguration.h"
#import "FBSDKError+Internal.h"
#import "FBSDKErrorFactory.h"
#import "FBSDKErrorReporter.h"
#import "FBSDKInternalUtility+Internal.h"
#import "FBSDKServerConfigurationManager+ServerConfigurationProviding.h"
#import "FBSDKServerConfigurationProviding.h"

@interface FBSDKBridgeAPIProtocolWebV2 ()

@property (nonatomic, readonly) id<FBSDKServerConfigurationProviding> serverConfigurationProvider;
@property (nonatomic, readonly) id<FBSDKBridgeAPIProtocol> nativeBridge;

@end

@implementation FBSDKBridgeAPIProtocolWebV2

#pragma mark - Object Lifecycle

- (instancetype)init
{
  id<FBSDKErrorCreating> errorFactory = [[FBSDKErrorFactory alloc] initWithReporter:FBSDKErrorReporter.shared];
  id<FBSDKBridgeAPIProtocol> nativeBridge = [[FBSDKBridgeAPIProtocolNativeV1 alloc] initWithAppScheme:nil
                                                                                           pasteboard:nil
                                                                                  dataLengthThreshold:0
                                                                                       includeAppIcon:NO
                                                                                         errorFactory:errorFactory];
  return [self initWithServerConfigurationProvider:FBSDKServerConfigurationManager.shared
                                      nativeBridge:nativeBridge];
}

- (instancetype)initWithServerConfigurationProvider:(id<FBSDKServerConfigurationProviding>)serverConfigurationProvider
                                       nativeBridge:(id<FBSDKBridgeAPIProtocol>)nativeBridge
{
  if ((self = [super init])) {
    _serverConfigurationProvider = serverConfigurationProvider;
    _nativeBridge = nativeBridge;
  }
  return self;
}

#pragma mark - FBSDKBridgeAPIProtocol

- (NSURL *)_redirectURLWithActionID:(NSString *)actionID methodName:(NSString *)methodName error:(NSError **)errorRef
{
  NSDictionary<NSString *, id> *queryParameters = nil;
  if (actionID) {
    NSDictionary<NSString *, id> *bridgeArgs = @{ FBSDKBridgeAPIProtocolNativeV1BridgeParameterInputKeys.actionID : actionID };
    NSString *bridgeArgsString = [FBSDKBasicUtility JSONStringForObject:bridgeArgs
                                                                  error:NULL
                                                   invalidObjectHandler:NULL];
    queryParameters = @{ FBSDKBridgeAPIProtocolNativeV1InputKeys.bridgeArgs : bridgeArgsString };
  }
  return [FBSDKInternalUtility.sharedUtility appURLWithHost:@"bridge" path:methodName queryParameters:queryParameters error:errorRef];
}

- (NSURL *)_requestURLForDialogConfiguration:(FBSDKDialogConfiguration *)dialogConfiguration error:(NSError **)errorRef
{
  NSURL *requestURL = dialogConfiguration.URL;
  if (!requestURL.scheme) {
    requestURL = [FBSDKInternalUtility.sharedUtility facebookURLWithHostPrefix:@"m"
                                                                          path:requestURL.path
                                                               queryParameters:@{}
                                                                defaultVersion:@""
                                                                         error:errorRef];
  }
  return requestURL;
}

- (nullable NSURL *)requestURLWithActionID:(NSString *)actionID
                                    scheme:(NSString *)scheme
                                methodName:(NSString *)methodName
                             methodVersion:(NSString *)methodVersion
                                parameters:(NSDictionary<NSString *, id> *)parameters
                                     error:(NSError *__autoreleasing *)errorRef
{
  FBSDKServerConfiguration *serverConfiguration = [self.serverConfigurationProvider cachedServerConfiguration];
  FBSDKDialogConfiguration *dialogConfiguration = [serverConfiguration dialogConfigurationForDialogName:methodName];
  if (!dialogConfiguration) {
    if (errorRef != NULL) {
      *errorRef = [FBSDKError errorWithCode:FBSDKErrorDialogUnavailable message:nil];
    }
    return nil;
  }

  NSURL *requestURL = [_nativeBridge requestURLWithActionID:actionID
                                                     scheme:scheme
                                                 methodName:methodName
                                              methodVersion:methodVersion
                                                 parameters:parameters error:errorRef];
  if (!requestURL) {
    return nil;
  }

  NSMutableDictionary<NSString *, id> *queryParameters = [[FBSDKBasicUtility dictionaryWithQueryString:requestURL.query] mutableCopy];
  [FBSDKTypeUtility dictionary:queryParameters setObject:NSBundle.mainBundle.bundleIdentifier forKey:@"ios_bundle_id"];
  NSURL *redirectURL = [self _redirectURLWithActionID:nil methodName:methodName error:errorRef];
  if (!redirectURL) {
    return nil;
  }
  [FBSDKTypeUtility dictionary:queryParameters setObject:redirectURL forKey:@"redirect_url"];

  requestURL = [self _requestURLForDialogConfiguration:dialogConfiguration error:errorRef];
  if (!requestURL) {
    return nil;
  }
  return [FBSDKInternalUtility.sharedUtility URLWithScheme:requestURL.scheme
                                                      host:requestURL.host
                                                      path:requestURL.path
                                           queryParameters:queryParameters
                                                     error:errorRef];
}

- (NSDictionary<NSString *, id> *)responseParametersForActionID:(NSString *)actionID
                                                queryParameters:(NSDictionary<NSString *, id> *)queryParameters
                                                      cancelled:(BOOL *)cancelledRef
                                                          error:(NSError *__autoreleasing *)errorRef
{
  return [_nativeBridge responseParametersForActionID:actionID
                                      queryParameters:queryParameters
                                            cancelled:cancelledRef
                                                error:errorRef];
}

@end

#endif
