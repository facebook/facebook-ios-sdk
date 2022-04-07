/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !TARGET_OS_TV

#import "FBSDKBridgeAPIRequest.h"
#import "FBSDKBridgeAPIRequest+Private.h"

#import <UIKit/UIApplication.h>

#import <FBSDKCoreKit_Basics/FBSDKCoreKit_Basics.h>

#import "FBSDKBridgeAPIProtocol.h"
#import "FBSDKBridgeAPIProtocolNativeV1.h"
#import "FBSDKBridgeAPIProtocolType.h"
#import "FBSDKBridgeAPIProtocolWebV1.h"
#import "FBSDKBridgeAPIProtocolWebV2.h"
#import "FBSDKInternalUtility+Internal.h"
#import "FBSDKSettings.h"
#import "FBSDKURLScheme.h"
#import "UIApplication+URLOpener.h"

NSString *const FBSDKBridgeAPIAppIDKey = @"app_id";
NSString *const FBSDKBridgeAPISchemeSuffixKey = @"scheme_suffix";
NSString *const FBSDKBridgeAPIVersionKey = @"version";

typedef NSDictionary<NSNumber *, NSDictionary<FBSDKURLScheme, id<FBSDKBridgeAPIProtocol>> *> *FBSDKBridgeAPIProtocolMap;

NS_ASSUME_NONNULL_BEGIN

@implementation FBSDKBridgeAPIRequest

#pragma mark - Class dependencies

static BOOL _hasBeenConfigured = NO;

+ (BOOL)hasBeenConfigured
{
  return _hasBeenConfigured;
}

+ (void)setHasBeenConfigured:(BOOL)hasBeenConfigured
{
  _hasBeenConfigured = hasBeenConfigured;
}

static _Nullable id<FBSDKInternalURLOpener> _internalURLOpener;

+ (nullable id<FBSDKInternalURLOpener>)internalURLOpener
{
  return _internalURLOpener;
}

+ (void)setInternalURLOpener:(nullable id<FBSDKInternalURLOpener>)internalURLOpener
{
  _internalURLOpener = internalURLOpener;
}

static _Nullable id<FBSDKInternalUtility> _internalUtility;

+ (nullable id<FBSDKInternalUtility>)internalUtility
{
  return _internalUtility;
}

+ (void)setInternalUtility:(nullable id<FBSDKInternalUtility>)internalUtility
{
  _internalUtility = internalUtility;
}

static _Nullable id<FBSDKSettings> _settings;

+ (nullable id<FBSDKSettings>)settings
{
  return _settings;
}

+ (void)setSettings:(nullable id<FBSDKSettings>)settings
{
  _settings = settings;
}

#pragma mark - Class Configuration

+ (void)configureWithInternalURLOpener:(id<FBSDKInternalURLOpener>)internalURLOpener
                       internalUtility:(id<FBSDKInternalUtility>)internalUtility
                              settings:(id<FBSDKSettings>)settings
{
  if (self.hasBeenConfigured) {
    return;
  }

  self.internalURLOpener = internalURLOpener;
  self.internalUtility = internalUtility;
  self.settings = settings;

  self.hasBeenConfigured = YES;
}

#if DEBUG

+ (void)resetClassDependencies
{
  self.internalURLOpener = nil;
  self.internalUtility = nil;
  self.settings = nil;

  self.hasBeenConfigured = NO;
}

#endif

#pragma mark - Class Methods

+ (nullable instancetype)bridgeAPIRequestWithProtocolType:(FBSDKBridgeAPIProtocolType)protocolType
                                                   scheme:(FBSDKURLScheme)scheme
                                               methodName:(nullable NSString *)methodName
                                               parameters:(nullable NSDictionary<NSString *, id> *)parameters
                                                 userInfo:(nullable NSDictionary<NSString *, id> *)userInfo
{
  return [[self alloc] initWithProtocol:[self _protocolForType:protocolType scheme:scheme]
                           protocolType:protocolType
                                 scheme:scheme
                             methodName:methodName
                             parameters:parameters
                               userInfo:userInfo];
}

+ (FBSDKBridgeAPIProtocolMap)protocolMap
{
  static FBSDKBridgeAPIProtocolMap map;
  if (!map) {
    map = @{
      @(FBSDKBridgeAPIProtocolTypeNative) : @{
        FBSDKURLSchemeFacebookAPI : [[FBSDKBridgeAPIProtocolNativeV1 alloc] initWithAppScheme:@"fbapi"],
        FBSDKURLSchemeMessengerApp : [[FBSDKBridgeAPIProtocolNativeV1 alloc] initWithAppScheme:@"fb-messenger-share-api"]
      },
      @(FBSDKBridgeAPIProtocolTypeWeb) : @{
        FBSDKURLSchemeHTTPS : [FBSDKBridgeAPIProtocolWebV1 new],
        FBSDKURLSchemeWeb : [FBSDKBridgeAPIProtocolWebV2 new]
      },
    };
  }

  return map;
}

#pragma mark - Object Lifecycle

- (nullable instancetype)initWithProtocol:(nullable id<FBSDKBridgeAPIProtocol>)protocol
                             protocolType:(FBSDKBridgeAPIProtocolType)protocolType
                                   scheme:(FBSDKURLScheme)scheme
                               methodName:(nullable NSString *)methodName
                               parameters:(nullable NSDictionary<NSString *, id> *)parameters
                                 userInfo:(nullable NSDictionary<NSString *, id> *)userInfo
{
  if (!protocol) {
    return nil;
  }
  if ((self = [super init])) {
    _protocol = protocol;
    _protocolType = protocolType;
    _scheme = [scheme copy];
    _methodName = [methodName copy];
    _parameters = [parameters copy];
    _userInfo = [userInfo copy];

    _actionID = [NSUUID UUID].UUIDString;
  }
  return self;
}

#pragma mark - Public Methods

- (nullable NSURL *)requestURL:(NSError *__autoreleasing *)errorRef
{
  NSURL *requestURL = [_protocol requestURLWithActionID:self.actionID
                                                 scheme:self.scheme
                                             methodName:self.methodName
                                             parameters:self.parameters
                                                  error:errorRef];
  if (!requestURL) {
    return nil;
  }

  [self.class.internalUtility validateURLSchemes];

  NSDictionary<NSString *, NSString *> *requestQueryParameters = [FBSDKBasicUtility dictionaryWithQueryString:requestURL.query];
  NSMutableDictionary<NSString *, id> *queryParameters = [[NSMutableDictionary alloc] initWithDictionary:requestQueryParameters];
  [FBSDKTypeUtility dictionary:queryParameters setObject:self.class.settings.appID forKey:FBSDKBridgeAPIAppIDKey];
  [FBSDKTypeUtility dictionary:queryParameters
                     setObject:self.class.settings.appURLSchemeSuffix
                        forKey:FBSDKBridgeAPISchemeSuffixKey];
  requestURL = [self.class.internalUtility URLWithScheme:requestURL.scheme
                                                    host:requestURL.host
                                                    path:requestURL.path
                                         queryParameters:queryParameters
                                                   error:errorRef];
  return requestURL;
}

#pragma mark - NSCopying

- (id)copyWithZone:(nullable NSZone *)zone
{
  return self;
}

+ (nullable id<FBSDKBridgeAPIProtocol>)_protocolForType:(FBSDKBridgeAPIProtocolType)type scheme:(FBSDKURLScheme)scheme
{
  id<FBSDKBridgeAPIProtocol> protocol = [self protocolMap][@(type)][scheme];
  if (type == FBSDKBridgeAPIProtocolTypeWeb) {
    return protocol;
  }
  NSURLComponents *components = [NSURLComponents new];
  components.scheme = scheme;
  components.path = @"/";
  if ([self.class.internalURLOpener canOpenURL:components.URL]) {
    return protocol;
  }
  return nil;
}

@end

NS_ASSUME_NONNULL_END

#endif
