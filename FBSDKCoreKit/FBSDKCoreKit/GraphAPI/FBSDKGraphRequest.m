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

#import "FBSDKGraphRequest+Internal.h"

#import <UIKit/UIKit.h>

#import "FBSDKCoreKitBasicsImport.h"
#import "FBSDKGraphRequestConnecting.h"
#import "FBSDKGraphRequestConnection.h"
#import "FBSDKGraphRequestConnectionFactory.h"
#import "FBSDKGraphRequestConnectionProviding.h"
#import "FBSDKGraphRequestDataAttachment.h"
#import "FBSDKInternalUtility.h"
#import "FBSDKLogger.h"
#import "FBSDKSettings+Internal.h"
#import "FBSDKTokenStringProviding.h"

// constants
FBSDKHTTPMethod FBSDKHTTPMethodGET = @"GET";
FBSDKHTTPMethod FBSDKHTTPMethodPOST = @"POST";
FBSDKHTTPMethod FBSDKHTTPMethodDELETE = @"DELETE";

static Class<FBSDKTokenStringProviding> _currentAccessTokenStringProvider;

@interface FBSDKGraphRequest ()
@property (nonatomic, readwrite, assign) FBSDKGraphRequestFlags flags;
@property (nonatomic, readwrite, copy) FBSDKHTTPMethod HTTPMethod;
@property (nonatomic, strong) id<FBSDKGraphRequestConnectionProviding> connectionFactory;
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
                       parameters:(NSDictionary *)parameters
{
  return [self initWithGraphPath:graphPath
                      parameters:parameters
                           flags:FBSDKGraphRequestFlagNone];
}

- (instancetype)initWithGraphPath:(NSString *)graphPath
                       parameters:(NSDictionary *)parameters
                       HTTPMethod:(FBSDKHTTPMethod)method
{
  return [self initWithGraphPath:graphPath
                      parameters:parameters
                     tokenString:[_currentAccessTokenStringProvider tokenString]
                         version:nil
                      HTTPMethod:method];
}

- (instancetype)initWithGraphPath:(NSString *)graphPath
                       parameters:(NSDictionary *)parameters
                            flags:(FBSDKGraphRequestFlags)requestFlags
{
  return [self initWithGraphPath:graphPath
                      parameters:parameters
                     tokenString:[_currentAccessTokenStringProvider tokenString]
                      HTTPMethod:FBSDKHTTPMethodGET
                           flags:requestFlags];
}

- (instancetype)initWithGraphPath:(NSString *)graphPath
                       parameters:(NSDictionary *)parameters
                      tokenString:(NSString *)tokenString
                       HTTPMethod:(FBSDKHTTPMethod)method
                            flags:(FBSDKGraphRequestFlags)requestFlags
{
  if ((self = [self initWithGraphPath:graphPath
                           parameters:parameters
                          tokenString:tokenString
                              version:[FBSDKSettings graphAPIVersion]
                           HTTPMethod:method])) {
    self.flags |= requestFlags;
  }
  return self;
}

- (instancetype)initWithGraphPath:(NSString *)graphPath
                       parameters:(NSDictionary *)parameters
                      tokenString:(NSString *)tokenString
                       HTTPMethod:(NSString *)method
                            flags:(FBSDKGraphRequestFlags)requestFlags
                connectionFactory:(id<FBSDKGraphRequestConnectionProviding>)factory
{
  return [self initWithGraphPath:graphPath
                      parameters:parameters
                     tokenString:tokenString
                      HTTPMethod:method
                         version:[FBSDKSettings graphAPIVersion]
                           flags:requestFlags
               connectionFactory:factory];
}

- (instancetype)initWithGraphPath:(NSString *)graphPath
                       parameters:(NSDictionary *)parameters
                      tokenString:(NSString *)tokenString
                       HTTPMethod:(NSString *)method
                          version:(NSString *)version
                            flags:(FBSDKGraphRequestFlags)requestFlags
                connectionFactory:(id<FBSDKGraphRequestConnectionProviding>)factory
{
  if ((self = [self initWithGraphPath:graphPath
                           parameters:parameters
                          tokenString:tokenString
                              version:version
                           HTTPMethod:method])) {
    self.flags |= requestFlags;
    self.connectionFactory = factory;
  }
  return self;
}

- (instancetype)initWithGraphPath:(NSString *)graphPath
                       parameters:(NSDictionary *)parameters
                      tokenString:(NSString *)tokenString
                          version:(NSString *)version
                       HTTPMethod:(FBSDKHTTPMethod)method
{
  if ((self = [super init])) {
    _tokenString = tokenString ? [tokenString copy] : nil;
    _version = version ? [version copy] : [FBSDKSettings graphAPIVersion];
    _graphPath = [graphPath copy];
    self.HTTPMethod = method.length > 0 ? [method copy] : FBSDKHTTPMethodGET;
    _parameters = parameters ?: @{};
    if (!FBSDKSettings.isGraphErrorRecoveryEnabled) {
      self.flags = FBSDKGraphRequestFlagDisableErrorRecovery;
    }
    _connectionFactory = [FBSDKGraphRequestConnectionFactory new];
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

+ (BOOL)isAttachment:(id)item
{
  return ([item isKindOfClass:[UIImage class]]
    || [item isKindOfClass:[NSData class]]
    || [item isKindOfClass:[FBSDKGraphRequestDataAttachment class]]);
}

+ (NSString *)serializeURL:(NSString *)baseUrl
                    params:(NSDictionary *)params
{
  return [self serializeURL:baseUrl params:params httpMethod:FBSDKHTTPMethodGET];
}

+ (NSString *)serializeURL:(NSString *)baseUrl
                    params:(NSDictionary *)params
                httpMethod:(NSString *)httpMethod
{
  return [self serializeURL:baseUrl params:params httpMethod:httpMethod forBatch:NO];
}

+ (NSString *)serializeURL:(NSString *)baseUrl
                    params:(NSDictionary *)params
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

+ (NSDictionary *)preprocessParams:(NSDictionary *)params
{
  NSString *debugValue = [FBSDKSettings graphAPIDebugParamValue];
  if (debugValue) {
    NSMutableDictionary *mutableParams = [NSMutableDictionary dictionaryWithDictionary:params];
    [FBSDKTypeUtility dictionary:mutableParams setObject:debugValue forKey:@"debug"];
    return mutableParams;
  }

  return params;
}

+ (void)setCurrentAccessTokenStringProvider:(Class<FBSDKTokenStringProviding>)provider
{
  if (_currentAccessTokenStringProvider != provider) {
    _currentAccessTokenStringProvider = provider;
  }
}

- (id<FBSDKGraphRequestConnecting>)startWithCompletionHandler:(FBSDKGraphRequestBlock)handler
{
  FBSDKGraphRequestCompletion completion = ^void (id<FBSDKGraphRequestConnecting> connection, id result, NSError *error) {
    handler(FBSDK_CAST_TO_CLASS_OR_NIL(connection, FBSDKGraphRequestConnection), result, error);
  };

  return [self startWithCompletion:completion];
}

- (id<FBSDKGraphRequestConnecting>)startWithCompletion:(FBSDKGraphRequestCompletion)completion
{
  id<FBSDKGraphRequestConnecting> connection = [self.connectionFactory createGraphRequestConnection];
  id<FBSDKGraphRequest> request = (id<FBSDKGraphRequest>)self;
  [connection addRequest:request completion:completion];
  [connection start];
  return connection;
}

#pragma mark - Debugging helpers

- (NSString *)description
{
  return [self formattedDescription];
}

- (NSString *)formattedDescription
{
  NSMutableString *result = [NSMutableString stringWithFormat:@"<%@: %p",
                             NSStringFromClass([self class]),
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

#if DEBUG
 #if FBSDKTEST

+ (void)reset
{
  _currentAccessTokenStringProvider = nil;
}

+ (Class<FBSDKTokenStringProviding>)currentAccessTokenStringProvider
{
  return _currentAccessTokenStringProvider;
}

 #endif
#endif

@end
