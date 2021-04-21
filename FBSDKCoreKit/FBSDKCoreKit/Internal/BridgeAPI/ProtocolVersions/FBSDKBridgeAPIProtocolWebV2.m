// Copyright (c) 2014-present, Facebook, Inc. All rights reserved.
//
// You are hereby granted a non-exclusive, worldwide, royalty-free license to use,
// copy, modify, and distribute this software in source code or binary form for use
// in connection with the web services and APIs provided by Facebook.
//
// As with any software that integrates with the Facebook platform, your use of
// this software is subject to the Facebook Developer Principles and Policies
// [http://developers.facebook.com/policy/]. This copyright notice shall be
// included in all copies or substantial portions of the software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
// FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
// COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
// IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
// CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

#import "TargetConditionals.h"

#if !TARGET_OS_TV

 #import "FBSDKBridgeAPIProtocolWebV2.h"

 #import "FBSDKBridgeAPIProtocolNativeV1.h"
 #import "FBSDKCoreKitBasicsImport.h"
 #import "FBSDKDialogConfiguration.h"
 #import "FBSDKError.h"
 #import "FBSDKInternalUtility.h"
 #import "FBSDKServerConfigurationManager.h"
 #import "FBSDKServerConfigurationProviding.h"

@interface FBSDKBridgeAPIProtocolWebV2 ()

@property (nonatomic, readonly) Class<FBSDKServerConfigurationProviding> serverConfigurationProvider;
@property (nonatomic, readonly) id<FBSDKBridgeAPIProtocol> nativeBridge;

@end

@implementation FBSDKBridgeAPIProtocolWebV2

 #pragma mark - Object Lifecycle

- (instancetype)init
{
  return [self initWithServerConfigurationProvider:FBSDKServerConfigurationManager.class
                                      nativeBridge:[[FBSDKBridgeAPIProtocolNativeV1 alloc] initWithAppScheme:nil
                                                                                                  pasteboard:nil
                                                                                         dataLengthThreshold:0
                                                                                              includeAppIcon:NO]];
}

- (instancetype)initWithServerConfigurationProvider:(Class<FBSDKServerConfigurationProviding>)serverConfigurationProvider
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
  NSDictionary *queryParameters = nil;
  if (actionID) {
    NSDictionary *bridgeArgs = @{ FBSDKBridgeAPIProtocolNativeV1BridgeParameterInputKeys.actionID : actionID };
    NSString *bridgeArgsString = [FBSDKBasicUtility JSONStringForObject:bridgeArgs
                                                                  error:NULL
                                                   invalidObjectHandler:NULL];
    queryParameters = @{ FBSDKBridgeAPIProtocolNativeV1InputKeys.bridgeArgs : bridgeArgsString };
  }
  return [FBSDKInternalUtility appURLWithHost:@"bridge" path:methodName queryParameters:queryParameters error:errorRef];
}

- (NSURL *)_requestURLForDialogConfiguration:(FBSDKDialogConfiguration *)dialogConfiguration error:(NSError **)errorRef
{
  NSURL *requestURL = dialogConfiguration.URL;
  if (!requestURL.scheme) {
    requestURL = [FBSDKInternalUtility facebookURLWithHostPrefix:@"m"
                                                            path:requestURL.path
                                                 queryParameters:@{}
                                                  defaultVersion:@""
                                                           error:errorRef];
  }
  return requestURL;
}

- (NSURL *)requestURLWithActionID:(NSString *)actionID
                           scheme:(NSString *)scheme
                       methodName:(NSString *)methodName
                    methodVersion:(NSString *)methodVersion
                       parameters:(NSDictionary *)parameters
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
  [FBSDKTypeUtility dictionary:queryParameters setObject:[NSBundle mainBundle].bundleIdentifier forKey:@"ios_bundle_id"];
  NSURL *redirectURL = [self _redirectURLWithActionID:nil methodName:methodName error:errorRef];
  if (!redirectURL) {
    return nil;
  }
  [FBSDKTypeUtility dictionary:queryParameters setObject:redirectURL forKey:@"redirect_url"];

  requestURL = [self _requestURLForDialogConfiguration:dialogConfiguration error:errorRef];
  if (!requestURL) {
    return nil;
  }
  return [FBSDKInternalUtility URLWithScheme:requestURL.scheme
                                        host:requestURL.host
                                        path:requestURL.path
                             queryParameters:queryParameters
                                       error:errorRef];
}

- (NSDictionary *)responseParametersForActionID:(NSString *)actionID
                                queryParameters:(NSDictionary *)queryParameters
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
