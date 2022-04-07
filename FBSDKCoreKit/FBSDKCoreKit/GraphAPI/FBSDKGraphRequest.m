/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "FBSDKGraphRequest+Internal.h"

#import <UIKit/UIKit.h>

#import <FBSDKCoreKit_Basics/FBSDKCoreKit_Basics.h>

#import "FBSDKGraphRequestConnecting.h"
#import "FBSDKGraphRequestConnection.h"
#import "FBSDKGraphRequestDataAttachment.h"
#import "FBSDKInternalUtility+Internal.h"
#import "FBSDKLogger.h"
#import "FBSDKSettingsProtocol.h"
#import "FBSDKTokenStringProviding.h"

// constants
FBSDKHTTPMethod FBSDKHTTPMethodGET = @"GET";
FBSDKHTTPMethod FBSDKHTTPMethodPOST = @"POST";
FBSDKHTTPMethod FBSDKHTTPMethodDELETE = @"DELETE";

static Class<FBSDKTokenStringProviding> _accessTokenProvider;
static id<FBSDKSettings> _settings;
static id<FBSDKGraphRequestConnectionFactory> class_graphRequestConnectionFactory;

@interface FBSDKGraphRequest ()
@property (nonatomic, readwrite, assign) FBSDKGraphRequestFlags flags;
@property (nonatomic, readwrite, copy) FBSDKHTTPMethod HTTPMethod;
@property (nonatomic, strong) id<FBSDKGraphRequestConnectionFactory> graphRequestConnectionFactory;
@end

@implementation FBSDKGraphRequest

@synthesize HTTPMethod;
@synthesize flags;

- (instancetype)initWithGraphPath:(NSString *)graphPath
{
  return [self initWithGraphPath:graphPath parameters:@{@"fields" : @""}];
}

- (instancetype)initWithGraphPath:(NSString *)graphPath
                       HTTPMethod:(FBSDKHTTPMethod)method
{
  if (method == FBSDKHTTPMethodGET) {
    return [self initWithGraphPath:graphPath parameters:@{@"fields" : @""} HTTPMethod:method];
  } else {
    return [self initWithGraphPath:graphPath parameters:@{} HTTPMethod:method];
  }
}

- (instancetype)initWithGraphPath:(NSString *)graphPath
                       parameters:(NSDictionary<NSString *, id> *)parameters
{
  return [self initWithGraphPath:graphPath
                      parameters:parameters
                           flags:FBSDKGraphRequestFlagNone];
}

- (instancetype)initWithGraphPath:(NSString *)graphPath
                       parameters:(NSDictionary<NSString *, id> *)parameters
                       HTTPMethod:(FBSDKHTTPMethod)method
{
  return [self initWithGraphPath:graphPath
                      parameters:parameters
                     tokenString:[self.class.accessTokenProvider tokenString]
                         version:nil
                      HTTPMethod:method];
}

- (instancetype)initWithGraphPath:(NSString *)graphPath
                       parameters:(nullable NSDictionary<NSString *, id> *)parameters
                            flags:(FBSDKGraphRequestFlags)requestFlags
{
  return [self initWithGraphPath:graphPath
                      parameters:parameters
                     tokenString:[self.class.accessTokenProvider tokenString]
                      HTTPMethod:FBSDKHTTPMethodGET
                           flags:requestFlags];
}

- (instancetype)initWithGraphPath:(NSString *)graphPath
                       parameters:(NSDictionary<NSString *, id> *)parameters
                      tokenString:(NSString *)tokenString
                       HTTPMethod:(FBSDKHTTPMethod)method
                            flags:(FBSDKGraphRequestFlags)requestFlags
{
  if ((self = [self initWithGraphPath:graphPath
                           parameters:parameters
                          tokenString:tokenString
                              version:self.class.settings.graphAPIVersion
                           HTTPMethod:method])) {
    self.flags |= requestFlags;
  }
  return self;
}

- (instancetype)initWithGraphPath:(NSString *)graphPath
                       parameters:(NSDictionary<NSString *, id> *)parameters
                      tokenString:(NSString *)tokenString
                       HTTPMethod:(NSString *)method
                            flags:(FBSDKGraphRequestFlags)requestFlags
    graphRequestConnectionFactory:(id<FBSDKGraphRequestConnectionFactory>)factory
{
  return [self initWithGraphPath:graphPath
                             parameters:parameters
                            tokenString:tokenString
                             HTTPMethod:method
                                version:self.class.settings.graphAPIVersion
                                  flags:requestFlags
          graphRequestConnectionFactory:factory];
}

- (instancetype)initWithGraphPath:(NSString *)graphPath
                       parameters:(NSDictionary<NSString *, id> *)parameters
                      tokenString:(NSString *)tokenString
                       HTTPMethod:(NSString *)method
                          version:(NSString *)version
                            flags:(FBSDKGraphRequestFlags)requestFlags
    graphRequestConnectionFactory:(id<FBSDKGraphRequestConnectionFactory>)graphRequestConnectionFactory
{
  if ((self = [self initWithGraphPath:graphPath
                           parameters:parameters
                          tokenString:tokenString
                              version:version
                           HTTPMethod:method])) {
    self.flags |= requestFlags;
    self.graphRequestConnectionFactory = graphRequestConnectionFactory;
  }
  return self;
}

- (instancetype)initWithGraphPath:(NSString *)graphPath
                       parameters:(NSDictionary<NSString *, id> *)parameters
                      tokenString:(NSString *)tokenString
                          version:(NSString *)version
                       HTTPMethod:(FBSDKHTTPMethod)method
{
  if ((self = [super init])) {
    _tokenString = tokenString ? [tokenString copy] : nil;
    _version = version ? [version copy] : self.class.settings.graphAPIVersion;
    _graphPath = [graphPath copy];
    self.HTTPMethod = method.length > 0 ? [method copy] : FBSDKHTTPMethodGET;
    _parameters = parameters ?: @{};

    if (!self.class.settings.isGraphErrorRecoveryEnabled) {
      self.flags = FBSDKGraphRequestFlagDisableErrorRecovery;
    }
    // Uses the graph request connection factory set in the `configure` method as a default
    _graphRequestConnectionFactory = self.class.graphRequestConnectionFactory;
  }

  return self;
}

- (BOOL)isGraphErrorRecoveryDisabled
{
  return (self.flags & FBSDKGraphRequestFlagDisableErrorRecovery);
}

- (void)setGraphErrorRecoveryDisabled:(BOOL)disable
{
  if (disable) {
    self.flags |= FBSDKGraphRequestFlagDisableErrorRecovery;
  } else {
    self.flags &= ~FBSDKGraphRequestFlagDisableErrorRecovery;
  }
}

- (BOOL)hasAttachments
{
  __block BOOL hasAttachments = NO;
  [FBSDKTypeUtility dictionary:self.parameters enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
    if ([FBSDKGraphRequest isAttachment:obj]) {
      hasAttachments = YES;
      *stop = YES;
    }
  }];
  return hasAttachments;
}

- (id<FBSDKGraphRequestConnecting>)startWithCompletion:(nullable FBSDKGraphRequestCompletion)completion
{
  id<FBSDKGraphRequestConnecting> connection = [self.graphRequestConnectionFactory createGraphRequestConnection];
  id<FBSDKGraphRequest> request = (id<FBSDKGraphRequest>)self;
  [connection addRequest:request completion:completion];
  [connection start];
  return connection;
}

+ (BOOL)isAttachment:(id)item
{
  return ([item isKindOfClass:UIImage.class]
    || [item isKindOfClass:NSData.class]
    || [item isKindOfClass:FBSDKGraphRequestDataAttachment.class]);
}

+ (NSString *)serializeURL:(NSString *)baseUrl
                    params:(NSDictionary<NSString *, id> *)params
{
  return [self serializeURL:baseUrl params:params httpMethod:FBSDKHTTPMethodGET];
}

+ (NSString *)serializeURL:(NSString *)baseUrl
                    params:(NSDictionary<NSString *, id> *)params
                httpMethod:(NSString *)httpMethod
{
  return [self serializeURL:baseUrl params:params httpMethod:httpMethod forBatch:NO];
}

+ (NSString *)serializeURL:(NSString *)baseUrl
                    params:(NSDictionary<NSString *, id> *)params
                httpMethod:(NSString *)httpMethod
                  forBatch:(BOOL)forBatch
{
  params = [self preprocessParams:params];

  #pragma clang diagnostic push
  #pragma clang diagnostic ignored "-Wdeprecated-declarations"
  NSURL *parsedURL = [NSURL URLWithString:[baseUrl stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
  #pragma clang diagnostic pop

  if ([httpMethod isEqualToString:FBSDKHTTPMethodPOST] && !forBatch) {
    return baseUrl;
  }

  NSString *queryPrefix = parsedURL.query ? @"&" : @"?";

  NSString *query = [FBSDKBasicUtility queryStringWithDictionary:params error:NULL invalidObjectHandler:^id (id object, BOOL *stop) {
    if ([self isAttachment:object]) {
      if ([httpMethod isEqualToString:FBSDKHTTPMethodGET]) {
        [FBSDKLogger singleShotLogEntry:FBSDKLoggingBehaviorDeveloperErrors logEntry:@"can not use GET to upload a file"];
      }
      return nil;
    }
    return object;
  }];
  return [NSString stringWithFormat:@"%@%@%@", baseUrl, queryPrefix, query];
}

+ (NSDictionary<NSString *, id> *)preprocessParams:(NSDictionary<NSString *, id> *)params
{
  NSString *debugValue = self.settings.graphAPIDebugParamValue;
  if (debugValue) {
    NSMutableDictionary<NSString *, id> *mutableParams = [NSMutableDictionary dictionaryWithDictionary:params];
    [FBSDKTypeUtility dictionary:mutableParams setObject:debugValue forKey:@"debug"];
    return mutableParams;
  }

  return params;
}

+ (nullable id<FBSDKSettings>)settings
{
  return _settings;
}

+ (void)setSettings:(nullable id<FBSDKSettings>)settings
{
  _settings = settings;
}

+ (nullable Class<FBSDKTokenStringProviding>)accessTokenProvider
{
  return _accessTokenProvider;
}

+ (void)setAccessTokenProvider:(nullable Class<FBSDKTokenStringProviding>)accessTokenProvider
{
  _accessTokenProvider = accessTokenProvider;
}

+ (nullable id<FBSDKGraphRequestConnectionFactory>)graphRequestConnectionFactory
{
  return class_graphRequestConnectionFactory;
}

+ (void)setGraphRequestConnectionFactory:(nullable id<FBSDKGraphRequestConnectionFactory>)graphRequestConnectionFactory
{
  class_graphRequestConnectionFactory = graphRequestConnectionFactory;
}

+ (void)     configureWithSettings:(id<FBSDKSettings>)settings
  currentAccessTokenStringProvider:(Class<FBSDKTokenStringProviding>)accessTokenProvider
     graphRequestConnectionFactory:(id<FBSDKGraphRequestConnectionFactory>)graphRequestConnectionFactory
{
  self.settings = settings;
  self.accessTokenProvider = accessTokenProvider;
  self.graphRequestConnectionFactory = graphRequestConnectionFactory;
}

#if DEBUG

+ (void)resetClassDependencies
{
  self.settings = nil;
  self.accessTokenProvider = nil;
  self.graphRequestConnectionFactory = nil;
}

#endif

#pragma mark - Debugging helpers

- (NSString *)description
{
  return [self formattedDescription];
}

- (NSString *)formattedDescription
{
  NSMutableString *result = [NSMutableString stringWithFormat:@"<%@: %p",
                             NSStringFromClass(self.class),
                             self];
  if (self.graphPath) {
    [result appendFormat:@", graphPath: %@", self.graphPath];
  }
  if (self.HTTPMethod) {
    [result appendFormat:@", HTTPMethod: %@", self.HTTPMethod];
  }
  [result appendFormat:@", parameters: %@>", self.parameters.description];
  return result;
}

@end
