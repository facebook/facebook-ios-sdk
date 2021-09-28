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

#if !TARGET_OS_TV

#import "FBSDKBridgeAPIRequest.h"
#import "FBSDKBridgeAPIRequest+Private.h"

#import <UIKit/UIApplication.h>

#import <FBSDKCoreKit_Basics/FBSDKCoreKit_Basics.h>

#import "FBSDKBridgeAPIProtocolNativeV1.h"
#import "FBSDKBridgeAPIProtocolWebV1.h"
#import "FBSDKBridgeAPIProtocolWebV2.h"
#import "FBSDKInternalUtility+Internal.h"
#import "FBSDKSettings.h"
#import "UIApplication+URLOpener.h"

NSString *const FBSDKBridgeAPIAppIDKey = @"app_id";
NSString *const FBSDKBridgeAPISchemeSuffixKey = @"scheme_suffix";
NSString *const FBSDKBridgeAPIVersionKey = @"version";

@implementation FBSDKBridgeAPIRequest

#pragma mark - Class dependencies

static BOOL _hasBeenConfigured;

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

+ (void)configureWithInternalURLOpener:(nonnull id<FBSDKInternalURLOpener>)internalURLOpener
                       internalUtility:(nonnull id<FBSDKInternalUtility>)internalUtility
                              settings:(nonnull id<FBSDKSettings>)settings
{
  self.internalURLOpener = internalURLOpener;
  self.internalUtility = internalUtility;
  self.settings = settings;

  self.hasBeenConfigured = YES;
}

+ (void)configureClassDependencies
{
  if (self.hasBeenConfigured) {
    return;
  }

  [self configureWithInternalURLOpener:UIApplication.sharedApplication
                       internalUtility:FBSDKInternalUtility.sharedUtility
                              settings:FBSDKSettings.sharedSettings];
}

#if FBTEST

+ (void)resetClassDependencies
{
  self.internalURLOpener = nil;
  self.internalUtility = nil;
  self.settings = nil;

  self.hasBeenConfigured = NO;
}

#endif

#pragma mark - Class Methods

+ (instancetype)bridgeAPIRequestWithProtocolType:(FBSDKBridgeAPIProtocolType)protocolType
                                          scheme:(NSString *)scheme
                                      methodName:(NSString *)methodName
                                   methodVersion:(NSString *)methodVersion
                                      parameters:(NSDictionary<NSString *, id> *)parameters
                                        userInfo:(NSDictionary<NSString *, id> *)userInfo
{
  return [[self alloc] initWithProtocol:[self _protocolForType:protocolType scheme:scheme]
                           protocolType:protocolType
                                 scheme:scheme
                             methodName:methodName
                          methodVersion:methodVersion
                             parameters:parameters
                               userInfo:userInfo];
}

+ (NSDictionary<NSNumber *, id> *)protocolMap
{
  static NSDictionary<NSNumber *, id> *_protocolMap;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    _protocolMap = @{
      @(FBSDKBridgeAPIProtocolTypeNative) : @{
        FBSDK_CANOPENURL_FACEBOOK : [[FBSDKBridgeAPIProtocolNativeV1 alloc] initWithAppScheme:@"fbapi20130214"],
        FBSDK_CANOPENURL_MESSENGER : [[FBSDKBridgeAPIProtocolNativeV1 alloc] initWithAppScheme:@"fb-messenger-share-api"],
        FBSDK_CANOPENURL_MSQRD_PLAYER : [[FBSDKBridgeAPIProtocolNativeV1 alloc] initWithAppScheme:@"msqrdplayer-api20170208"]
      },
      @(FBSDKBridgeAPIProtocolTypeWeb) : @{
        @"https" : [FBSDKBridgeAPIProtocolWebV1 new],
        @"web" : [FBSDKBridgeAPIProtocolWebV2 new]
      },
    };
  });
  return _protocolMap;
}

#pragma mark - Object Lifecycle

- (nullable instancetype)initWithProtocol:(nullable id<FBSDKBridgeAPIProtocol>)protocol
                             protocolType:(FBSDKBridgeAPIProtocolType)protocolType
                                   scheme:(nonnull NSString *)scheme
                               methodName:(nullable NSString *)methodName
                            methodVersion:(nullable NSString *)methodVersion
                               parameters:(nullable NSDictionary<NSString *, id> *)parameters
                                 userInfo:(nullable NSDictionary<NSString *, id> *)userInfo
{
  [self.class configureClassDependencies];

  if (!protocol) {
    return nil;
  }
  if ((self = [super init])) {
    _protocol = protocol;
    _protocolType = protocolType;
    _scheme = [scheme copy];
    _methodName = [methodName copy];
    _methodVersion = [methodVersion copy];
    _parameters = [parameters copy];
    _userInfo = [userInfo copy];

    _actionID = [NSUUID UUID].UUIDString;
  }
  return self;
}

#pragma mark - Public Methods

- (NSURL *)requestURL:(NSError *__autoreleasing *)errorRef
{
  NSURL *requestURL = [_protocol requestURLWithActionID:self.actionID
                                                 scheme:self.scheme
                                             methodName:self.methodName
                                          methodVersion:self.methodVersion
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

- (id)copyWithZone:(NSZone *)zone
{
  return self;
}

+ (id<FBSDKBridgeAPIProtocol>)_protocolForType:(FBSDKBridgeAPIProtocolType)type scheme:(NSString *)scheme
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

#endif
