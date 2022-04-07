/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "FBSDKGraphRequestConnection+Internal.h"

#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import <FBSDKCoreKit/FBSDKGraphRequestConnectionDelegate.h>

#import "FBSDKAccessToken.h"
#import "FBSDKAuthenticationToken.h"
#import "FBSDKCoreKitVersions.h"
#import "FBSDKErrorConfigurationProvider.h"
#import "FBSDKErrorRecoveryAttempter.h"
#import "FBSDKGraphRequest+Internal.h"
#import "FBSDKGraphRequestBody.h"
#import "FBSDKGraphRequestConnectionFactoryProtocol.h"
#import "FBSDKGraphRequestDataAttachment.h"
#import "FBSDKInternalUtility+Internal.h"
#import "FBSDKLogger+Internal.h"
#import "FBSDKOperatingSystemVersionComparing.h"
#import "FBSDKSafeCast.h"
#import "FBSDKSettingsProtocol.h"
#import "FBSDKURLSessionProxying.h"

NSString *const FBSDKNonJSONResponseProperty = @"FACEBOOK_NON_JSON_RESULT";

// URL construction constants
static NSString *const kGraphURLPrefix = @"graph.";
static NSString *const kGraphVideoURLPrefix = @"graph-video.";

static NSString *const kBatchKey = @"batch";
static NSString *const kBatchMethodKey = @"method";
static NSString *const kBatchRelativeURLKey = @"relative_url";
static NSString *const kBatchAttachmentKey = @"attached_files";
static NSString *const kBatchFileNamePrefix = @"file";
static NSString *const kBatchEntryName = @"name";

static NSString *const kAccessTokenKey = @"access_token";
#if TARGET_OS_TV
static NSString *const kSDK = @"tvos";
static NSString *const kUserAgentBase = @"FBtvOSSDK";
#else
static NSString *const kSDK = @"ios";
static NSString *const kUserAgentBase = @"FBiOSSDK";
#endif
static NSString *const kBatchRestMethodBaseURL = @"method/";

static NSTimeInterval g_defaultTimeout = 60.0;

#if !TARGET_OS_TV
static FBSDKAccessToken *_Nullable _CreateExpiredAccessToken(FBSDKAccessToken *accessToken)
{
  if (accessToken == nil) {
    return nil;
  }
  if (accessToken.isExpired) {
    return accessToken;
  }
  NSDate *expirationDate = [NSDate dateWithTimeIntervalSinceNow:-1];

  return [[FBSDKAccessToken alloc] initWithTokenString:accessToken.tokenString
                                           permissions:accessToken.permissions.allObjects
                                   declinedPermissions:accessToken.declinedPermissions.allObjects
                                    expiredPermissions:accessToken.expiredPermissions.allObjects
                                                 appID:accessToken.appID
                                                userID:accessToken.userID
                                        expirationDate:expirationDate
                                           refreshDate:expirationDate
                              dataAccessExpirationDate:expirationDate];
}

#endif

// ----------------------------------------------------------------------------
// Private properties and methods

@interface FBSDKGraphRequestConnection ()
#if TARGET_OS_TV
<NSURLSessionDataDelegate>
#else
<NSURLSessionDataDelegate, FBSDKGraphErrorRecoveryProcessorDelegate>
#endif

@property (class, nonatomic) BOOL hasBeenConfigured;

@end

// ----------------------------------------------------------------------------
// FBSDKGraphRequestConnection

@implementation FBSDKGraphRequestConnection

static BOOL _canMakeRequests = NO;

// MARK: Dependency Management

static BOOL _hasBeenConfigured = NO;
static id<FBSDKURLSessionProxyProviding> _sessionProxyFactory;
static id<FBSDKErrorConfigurationProviding> _errorConfigurationProvider;
static Class<FBSDKGraphRequestPiggybackManaging> _piggybackManager;
static id<FBSDKSettings> _settings;
static id<FBSDKGraphRequestConnectionFactory> _graphRequestConnectionFactory;
static id<FBSDKEventLogging> _eventLogger;
static id<FBSDKOperatingSystemVersionComparing> _operatingSystemVersionComparer;
static id<FBSDKMacCatalystDetermining> _macCatalystDeterminator;
static Class<FBSDKAccessTokenProviding> _accessTokenProvider;
static Class<FBSDKAccessTokenSetting> _accessTokenSetter;
static id<FBSDKErrorCreating> _errorFactory;
static Class<FBSDKAuthenticationTokenProviding> _authenticationTokenProvider;

+ (BOOL)hasBeenConfigured
{
  return _hasBeenConfigured;
}

+ (void)setHasBeenConfigured:(BOOL)hasBeenConfigured
{
  _hasBeenConfigured = hasBeenConfigured;
}

+ (nullable id<FBSDKURLSessionProxyProviding>)sessionProxyFactory
{
  return _sessionProxyFactory;
}

+ (void)setSessionProxyFactory:(nullable id<FBSDKURLSessionProxyProviding>)sessionProxyFactory
{
  _sessionProxyFactory = sessionProxyFactory;
}

+ (nullable id<FBSDKErrorConfigurationProviding>)errorConfigurationProvider
{
  return _errorConfigurationProvider;
}

+ (void)setErrorConfigurationProvider:(nullable id<FBSDKErrorConfigurationProviding>)errorConfigurationProvider
{
  _errorConfigurationProvider = errorConfigurationProvider;
}

+ (nullable Class<FBSDKGraphRequestPiggybackManaging>)piggybackManager
{
  return _piggybackManager;
}

+ (void)setPiggybackManager:(nullable Class<FBSDKGraphRequestPiggybackManaging>)piggybackManager
{
  _piggybackManager = piggybackManager;
}

+ (nullable id<FBSDKSettings>)settings
{
  return _settings;
}

+ (void)setSettings:(nullable id<FBSDKSettings>)settings
{
  _settings = settings;
}

+ (nullable id<FBSDKGraphRequestConnectionFactory>)graphRequestConnectionFactory
{
  return _graphRequestConnectionFactory;
}

+ (void)setGraphRequestConnectionFactory:(nullable id<FBSDKGraphRequestConnectionFactory>)graphRequestConnectionFactory
{
  _graphRequestConnectionFactory = graphRequestConnectionFactory;
}

+ (nullable id<FBSDKEventLogging>)eventLogger
{
  return _eventLogger;
}

+ (void)setEventLogger:(nullable id<FBSDKEventLogging>)eventLogger
{
  _eventLogger = eventLogger;
}

+ (nullable id<FBSDKOperatingSystemVersionComparing>)operatingSystemVersionComparer
{
  return _operatingSystemVersionComparer;
}

+ (void)setOperatingSystemVersionComparer:(nullable id<FBSDKOperatingSystemVersionComparing>)operatingSystemVersionComparer
{
  _operatingSystemVersionComparer = operatingSystemVersionComparer;
}

+ (nullable id<FBSDKMacCatalystDetermining>)macCatalystDeterminator
{
  return _macCatalystDeterminator;
}

+ (void)setMacCatalystDeterminator:(nullable id<FBSDKMacCatalystDetermining>)macCatalystDeterminator
{
  _macCatalystDeterminator = macCatalystDeterminator;
}

+ (nullable Class<FBSDKAccessTokenProviding>)accessTokenProvider
{
  return _accessTokenProvider;
}

+ (void)setAccessTokenProvider:(nullable Class<FBSDKAccessTokenProviding>)accessTokenProvider
{
  _accessTokenProvider = accessTokenProvider;
}

+ (nullable Class<FBSDKAccessTokenSetting>)accessTokenSetter
{
  return _accessTokenSetter;
}

+ (void)setAccessTokenSetter:(nullable Class<FBSDKAccessTokenSetting>)accessTokenSetter
{
  _accessTokenSetter = accessTokenSetter;
}

+ (nullable id<FBSDKErrorCreating>)errorFactory
{
  return _errorFactory;
}

+ (void)setErrorFactory:(nullable id<FBSDKErrorCreating>)errorFactory
{
  _errorFactory = errorFactory;
}

+ (nullable Class<FBSDKAuthenticationTokenProviding>)authenticationTokenProvider
{
  return _authenticationTokenProvider;
}

+ (void)setAuthenticationTokenProvider:(nullable Class<FBSDKAuthenticationTokenProviding>)authenticationTokenProvider
{
  _authenticationTokenProvider = authenticationTokenProvider;
}

+ (void)configureWithURLSessionProxyFactory:(nonnull id<FBSDKURLSessionProxyProviding>)proxyFactory
                 errorConfigurationProvider:(nonnull id<FBSDKErrorConfigurationProviding>)errorConfigurationProvider
                           piggybackManager:(nonnull id<FBSDKGraphRequestPiggybackManaging>)piggybackManager
                                   settings:(nonnull id<FBSDKSettings>)settings
              graphRequestConnectionFactory:(nonnull id<FBSDKGraphRequestConnectionFactory>)factory
                                eventLogger:(nonnull id<FBSDKEventLogging>)eventLogger
             operatingSystemVersionComparer:(nonnull id<FBSDKOperatingSystemVersionComparing>)operatingSystemVersionComparer
                    macCatalystDeterminator:(nonnull id<FBSDKMacCatalystDetermining>)macCatalystDeterminator
                        accessTokenProvider:(nonnull Class<FBSDKAccessTokenProviding>)accessTokenProvider
                          accessTokenSetter:(nonnull Class<FBSDKAccessTokenSetting>)accessTokenSetter
                               errorFactory:(nonnull id<FBSDKErrorCreating>)errorFactory
                authenticationTokenProvider:(nonnull Class<FBSDKAuthenticationTokenProviding>)authenticationTokenProvider
{
  if (self.hasBeenConfigured) {
    return;
  }

  self.sessionProxyFactory = proxyFactory;
  self.errorConfigurationProvider = errorConfigurationProvider;
  self.piggybackManager = piggybackManager;
  self.settings = settings;
  self.graphRequestConnectionFactory = factory;
  self.eventLogger = eventLogger;
  self.operatingSystemVersionComparer = operatingSystemVersionComparer;
  self.macCatalystDeterminator = macCatalystDeterminator;
  self.accessTokenProvider = accessTokenProvider;
  self.accessTokenSetter = accessTokenSetter;
  self.errorFactory = errorFactory;
  self.authenticationTokenProvider = authenticationTokenProvider;

  self.hasBeenConfigured = YES;
}

#if DEBUG

+ (void)resetClassDependencies
{
  self.hasBeenConfigured = NO;
  self.sessionProxyFactory = nil;
  self.errorConfigurationProvider = nil;
  self.piggybackManager = nil;
  self.settings = nil;
  self.graphRequestConnectionFactory = nil;
  self.eventLogger = nil;
  self.operatingSystemVersionComparer = nil;
  self.macCatalystDeterminator = nil;
  self.accessTokenProvider = nil;
  self.accessTokenSetter = nil;
  self.errorFactory = nil;
  self.authenticationTokenProvider = nil;
}

#endif

- (instancetype)init
{
  if ((self = [super init])) {
    _timeout = g_defaultTimeout;
    _session = [self.class.sessionProxyFactory createSessionProxyWithDelegate:self queue:_delegateQueue];
    _state = FBSDKGraphRequestConnectionStateCreated;
    _requests = [NSMutableArray new];
    _logger = [[FBSDKLogger alloc] initWithLoggingBehavior:FBSDKLoggingBehaviorNetworkRequests];
  }
  return self;
}

- (void)dealloc
{
  [self.session invalidateAndCancel];
}

#pragma mark - Public

+ (void)setDefaultConnectionTimeout:(NSTimeInterval)defaultTimeout
{
  if (defaultTimeout >= 0) {
    g_defaultTimeout = defaultTimeout;
  }
}

+ (NSTimeInterval)defaultConnectionTimeout
{
  return g_defaultTimeout;
}

- (void)addRequest:(id<FBSDKGraphRequest>)request
        completion:(FBSDKGraphRequestCompletion)completion
{
  [self addRequest:request name:@"" completion:completion];
}

- (void)addRequest:(id<FBSDKGraphRequest>)request
              name:(NSString *)name
        completion:(FBSDKGraphRequestCompletion)completion
{
  NSDictionary<NSString *, id> *batchParams = name.length > 0 ? @{kBatchEntryName : name } : nil;
  [self addRequest:request parameters:batchParams completion:completion];
}

- (void)addRequest:(id<FBSDKGraphRequest>)request
        parameters:(nullable NSDictionary<NSString *, id> *)parameters
        completion:(FBSDKGraphRequestCompletion)completion
{
  if (self.state != FBSDKGraphRequestConnectionStateCreated) {
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:@"Cannot add requests once started or if a URLRequest is set"
                                 userInfo:nil];
  }
  FBSDKGraphRequestMetadata *metadata = [[FBSDKGraphRequestMetadata alloc] initWithRequest:request
                                                                         completionHandler:completion
                                                                           batchParameters:parameters];

  [FBSDKTypeUtility array:self.requests addObject:metadata];
}

- (void)cancel
{
  self.state = FBSDKGraphRequestConnectionStateCancelled;
  [self.session invalidateAndCancel];
}

- (void)overrideGraphAPIVersion:(NSString *)version
{
  self.overriddenVersionPart = [version copy];
}

- (void)start
{
  if (![self.class canMakeRequests]) {
    NSString *msg = @"FBSDKGraphRequestConnection cannot be started before Facebook SDK initialized.";
    NSError *error = [self.class.errorFactory unknownErrorWithMessage:msg userInfo:nil];
    // TODO: Use a logger provider for this.
    [self.logger.class singleShotLogEntry:FBSDKLoggingBehaviorDeveloperErrors
                                 logEntry:msg];
    self.state = FBSDKGraphRequestConnectionStateCancelled;
    [self completeFBSDKURLSessionWithResponse:nil data:nil networkError:error];

    return;
  }

  if (self.state != FBSDKGraphRequestConnectionStateCreated
      && self.state != FBSDKGraphRequestConnectionStateSerialized) {
    [self.logger.class singleShotLogEntry:FBSDKLoggingBehaviorDeveloperErrors
                                 logEntry:@"FBSDKGraphRequestConnection cannot be started again."];
    return;
  }
  [self.class.piggybackManager addPiggybackRequests:self];
  NSMutableURLRequest *request = [self requestWithBatch:self.requests timeout:self.timeout];

  self.state = FBSDKGraphRequestConnectionStateStarted;

  [self logRequest:request bodyLength:0 bodyLogger:nil attachmentLogger:nil];
  self.requestStartTime = [FBSDKInternalUtility.sharedUtility currentTimeInMilliseconds];

  FBSDKURLSessionTaskBlock completionHandler = ^(NSData *responseDataV1, NSURLResponse *responseV1, NSError *errorV1) {
    FBSDKURLSessionTaskBlock handler = ^(NSData *responseDataV2,
                                         NSURLResponse *responseV2,
                                         NSError *errorV2) {
      [self completeFBSDKURLSessionWithResponse:responseV2
                                           data:responseDataV2
                                   networkError:errorV2];
    };

    if (errorV1) {
      [self _taskDidCompleteWithError:errorV1 handler:handler];
    } else {
      [self taskDidCompleteWithResponse:responseV1 data:responseDataV1 requestStartTime:self.requestStartTime handler:handler];
    }
  };
  [self.session executeURLRequest:request completionHandler:completionHandler];

  id<FBSDKGraphRequestConnectionDelegate> delegate = self.delegate;
  if ([delegate respondsToSelector:@selector(requestConnectionWillBeginLoading:)]) {
    if (self.delegateQueue) {
      [self.delegateQueue addOperationWithBlock:^{
        [delegate requestConnectionWillBeginLoading:self];
      }];
    } else {
      [delegate requestConnectionWillBeginLoading:self];
    }
  }
}

- (void)setDelegateQueue:(NSOperationQueue *)queue
{
  self.session.delegateQueue = queue;
  _delegateQueue = queue;
}

#pragma mark - Private Properties

+ (void)setCanMakeRequests
{
  _canMakeRequests = YES;
}

+ (BOOL)canMakeRequests
{
  return _canMakeRequests;
}

#pragma mark - Private methods (request generation)

//
// Adds request data to a batch in a format expected by the JsonWriter.
// Binary attachments are referenced by name in JSON and added to the
// attachments dictionary.
//
- (void)addRequest:(FBSDKGraphRequestMetadata *)metadata
           toBatch:(NSMutableArray<NSMutableDictionary<NSString *, id> *> *)batch
       attachments:(NSMutableDictionary<NSString *, id> *)attachments
        batchToken:(NSString *)batchToken
{
  NSMutableDictionary<NSString *, id> *requestElement = [NSMutableDictionary new];

  if (metadata.batchParameters) {
    [requestElement addEntriesFromDictionary:metadata.batchParameters];
  }

  if (batchToken) {
    NSMutableDictionary<NSString *, id> *params = [NSMutableDictionary
                                                   dictionaryWithDictionary:metadata.request.parameters];
    [FBSDKTypeUtility dictionary:params setObject:batchToken forKey:kAccessTokenKey];
    metadata.request.parameters = params;
    [self registerTokenToOmitFromLog:batchToken];
  }

  NSString *urlString = [self urlStringForSingleRequest:metadata.request forBatch:YES];
  [FBSDKTypeUtility dictionary:requestElement setObject:urlString forKey:kBatchRelativeURLKey];
  [FBSDKTypeUtility dictionary:requestElement setObject:metadata.request.HTTPMethod forKey:kBatchMethodKey];

  NSMutableArray<NSString *> *attachmentNames = [NSMutableArray array];

  [FBSDKTypeUtility dictionary:metadata.request.parameters enumerateKeysAndObjectsUsingBlock:^(id key, id value, BOOL *stop) {
    if ([FBSDKGraphRequest isAttachment:value]) {
      NSString *name = [NSString stringWithFormat:@"%@%lu",
                        kBatchFileNamePrefix,
                        (unsigned long)attachments.count];
      [FBSDKTypeUtility array:attachmentNames addObject:name];
      [FBSDKTypeUtility dictionary:attachments setObject:value forKey:name];
    }
  }];

  if (attachmentNames.count) {
    [FBSDKTypeUtility dictionary:requestElement setObject:[attachmentNames componentsJoinedByString:@","] forKey:kBatchAttachmentKey];
  }

  [FBSDKTypeUtility array:batch addObject:requestElement];
}

- (void)appendAttachments:(NSDictionary<NSString *, id> *)attachments
                   toBody:(FBSDKGraphRequestBody *)body
              addFormData:(BOOL)addFormData
                   logger:(FBSDKLogger *)logger
{
  [FBSDKTypeUtility dictionary:attachments enumerateKeysAndObjectsUsingBlock:^(id key, id value, BOOL *stop) {
    value = [FBSDKBasicUtility convertRequestValue:value];
    if ([value isKindOfClass:NSString.class]) {
      if (addFormData) {
        [body appendWithKey:key formValue:(NSString *)value logger:logger];
      }
    } else if ([value isKindOfClass:UIImage.class]) {
      [body appendWithKey:key imageValue:(UIImage *)value logger:logger];
    } else if ([value isKindOfClass:NSData.class]) {
      [body appendWithKey:key dataValue:(NSData *)value logger:logger];
    } else if ([value isKindOfClass:FBSDKGraphRequestDataAttachment.class]) {
      [body appendWithKey:key dataAttachmentValue:(FBSDKGraphRequestDataAttachment *)value logger:logger];
    } else {
      NSString *msg = [NSString stringWithFormat:@"Unsupported FBSDKGraphRequest attachment:%@, skipping.", value];
      [logger.class singleShotLogEntry:FBSDKLoggingBehaviorDeveloperErrors logEntry:msg];
    }
  }];
}

//
// Serializes all requests in the batch to JSON and appends the result to
// body.  Also names all attachments that need to go as separate blocks in
// the body of the request.
//
// All the requests are serialized into JSON, with any binary attachments
// named and referenced by name in the JSON.
//
- (void)appendJSONRequests:(NSArray<FBSDKGraphRequestMetadata *> *)requests
                    toBody:(FBSDKGraphRequestBody *)body
        andNameAttachments:(NSMutableDictionary<NSString *, id> *)attachments
                    logger:(FBSDKLogger *)logger
{
  NSMutableArray<NSMutableDictionary<NSString *, id> *> *batch = [NSMutableArray new];
  NSString *batchToken = nil;
  for (FBSDKGraphRequestMetadata *metadata in requests) {
    NSString *individualToken = [self accessTokenWithRequest:metadata.request];
    BOOL isClientToken = self.class.settings.clientToken && [individualToken hasSuffix:self.class.settings.clientToken];
    if (!batchToken
        && !isClientToken) {
      batchToken = individualToken;
    }
    [self addRequest:metadata
             toBatch:batch
         attachments:attachments
          batchToken:[batchToken isEqualToString:individualToken] ? nil : individualToken];
  }

  NSString *jsonBatch = [FBSDKBasicUtility JSONStringForObject:batch error:NULL invalidObjectHandler:NULL];

  [body appendWithKey:kBatchKey formValue:jsonBatch logger:logger];
  if (batchToken) {
    [body appendWithKey:kAccessTokenKey formValue:batchToken logger:logger];
  }
}

- (BOOL)_shouldWarnOnMissingFieldsParam:(id<FBSDKGraphRequest>)request
{
  NSString *minVersion = @"2.4";
  NSString *version = request.version;
  if (!version) {
    return YES;
  }
  if ([version hasPrefix:@"v"]) {
    version = [version substringFromIndex:1];
  }

  NSComparisonResult result = [version compare:minVersion options:NSNumericSearch];

  // if current version is the same as minVersion, or if the current version is > minVersion
  return (result == NSOrderedSame) || (result == NSOrderedDescending);
}

// Validate that all GET requests after v2.4 have a "fields" param
- (void)_validateFieldsParamForGetRequests:(NSArray<FBSDKGraphRequestMetadata *> *)requests
{
  for (FBSDKGraphRequestMetadata *metadata in requests) {
    id<FBSDKGraphRequest> request = metadata.request;
    if ([request.HTTPMethod.uppercaseString isEqualToString:@"GET"]
        && [self _shouldWarnOnMissingFieldsParam:request]
        && !request.parameters[@"fields"]
        && [request.graphPath rangeOfString:@"fields="].location == NSNotFound) {
      NSString *msg = [NSString stringWithFormat:@"starting with Graph API v2.4, GET requests for /%@ should contain an explicit \"fields\" parameter", request.graphPath];
      [FBSDKLogger singleShotLogEntry:FBSDKLoggingBehaviorDeveloperErrors
                             logEntry:msg];
    }
  }
}

//
// Generates a NSURLRequest based on the contents of self.requests, and sets
// options on the request.  Chooses between URL-based request for a single
// request and JSON-based request for batches.
//
- (NSMutableURLRequest *)requestWithBatch:(NSArray<FBSDKGraphRequestMetadata *> *)requests
                                  timeout:(NSTimeInterval)timeout
{
  FBSDKGraphRequestBody *body = [FBSDKGraphRequestBody new];
  FBSDKLogger *bodyLogger = [[FBSDKLogger alloc] initWithLoggingBehavior:self.logger.loggingBehavior];
  FBSDKLogger *attachmentLogger = [[FBSDKLogger alloc] initWithLoggingBehavior:self.logger.loggingBehavior];

  NSMutableURLRequest *request;

  if (requests.count == 0) {
    [[NSException exceptionWithName:NSInvalidArgumentException
                             reason:@"FBSDKGraphRequestConnection: Must have at least one request or urlRequest not specified."
                           userInfo:nil]
     raise];
  }

  [self _validateFieldsParamForGetRequests:requests];

  if (requests.count == 1) {
    FBSDKGraphRequestMetadata *metadata = requests.firstObject;
    NSURL *url = [NSURL URLWithString:[self urlStringForSingleRequest:metadata.request forBatch:NO]];
    request = [NSMutableURLRequest requestWithURL:url
                                      cachePolicy:NSURLRequestUseProtocolCachePolicy
                                  timeoutInterval:timeout];

    // HTTP methods are case-sensitive; be helpful in case someone provided a mixed case one.
    NSString *httpMethod = metadata.request.HTTPMethod.uppercaseString;
    request.HTTPMethod = httpMethod;
    [self appendAttachments:metadata.request.parameters
                     toBody:body
                addFormData:[httpMethod isEqualToString:@"POST"]
                     logger:attachmentLogger];
  } else {
    // Find the session with an app ID and use that as the batch_app_id. If we can't
    // find one, try to load it from the plist. As a last resort, pass 0.
    NSString *batchAppID = self.class.settings.appID;
    if (!batchAppID || batchAppID.length == 0) {
      // The Graph API batch method requires either an access token or batch_app_id.
      // If we can't determine an App ID to use for the batch, we can't issue it.
      [[NSException exceptionWithName:NSInternalInconsistencyException
                               reason:@"FBSDKGraphRequestConnection: _settings.appID must be specified for batch requests"
                             userInfo:nil]
       raise];
    }

    [body appendWithKey:@"batch_app_id" formValue:batchAppID logger:bodyLogger];

    NSMutableDictionary<NSString *, id> *attachments = [NSMutableDictionary new];

    [self appendJSONRequests:requests
                      toBody:body
          andNameAttachments:attachments
                      logger:bodyLogger];

    [self appendAttachments:attachments
                     toBody:body
                addFormData:NO
                     logger:attachmentLogger];

    NSURL *url = [FBSDKInternalUtility.sharedUtility
                  facebookURLWithHostPrefix:kGraphURLPrefix
                  path:@""
                  queryParameters:@{}
                  defaultVersion:self.overriddenVersionPart
                  error:NULL];

    request = [NSMutableURLRequest requestWithURL:url
                                      cachePolicy:NSURLRequestUseProtocolCachePolicy
                                  timeoutInterval:timeout];
    request.HTTPMethod = @"POST";
  }

  if ([request.HTTPMethod isEqualToString:@"POST"]) {
    [self addBody:body toPostRequest:request];
  } else {
    request.HTTPBody = body.data;
  }
  [request setValue:[self userAgent] forHTTPHeaderField:@"User-Agent"];
  [request setValue:[body mimeContentType] forHTTPHeaderField:@"Content-Type"];
  request.HTTPShouldHandleCookies = NO;

  [self logRequest:request bodyLength:(request.HTTPBody.length / 1024) bodyLogger:bodyLogger attachmentLogger:attachmentLogger];

  return request;
}

- (void)addBody:(FBSDKGraphRequestBody *)body toPostRequest:(NSMutableURLRequest *)request
{
  NSData *compressedData;
  if ((compressedData = [body compressedData])) {
    request.HTTPBody = compressedData;
    [request setValue:@"gzip" forHTTPHeaderField:@"Content-Encoding"];
  } else {
    request.HTTPBody = body.data;
  }
}

//
// Generates a URL for a batch containing only a single request,
// and names all attachments that need to go in the body of the
// request.
//
// The URL contains all parameters that are not body attachments,
// including the session key if present.
//
// Attachments are named and referenced by name in the URL.
//
- (NSString *)urlStringForSingleRequest:(id<FBSDKGraphRequest>)request forBatch:(BOOL)forBatch
{
  NSMutableDictionary<NSString *, id> *params = [NSMutableDictionary dictionaryWithDictionary:request.parameters];
  [FBSDKTypeUtility dictionary:params setObject:@"json" forKey:@"format"];
  [FBSDKTypeUtility dictionary:params setObject:kSDK forKey:@"sdk"];
  [FBSDKTypeUtility dictionary:params setObject:@"false" forKey:@"include_headers"];

  request.parameters = params;

  NSString *baseURL;
  if (forBatch) {
    baseURL = request.graphPath;
  } else {
    NSString *token = [self accessTokenWithRequest:request];
    if (token) {
      [params setValue:token forKey:kAccessTokenKey];
      request.parameters = params;
      [self registerTokenToOmitFromLog:token];
    }

    NSString *prefix = kGraphURLPrefix;
    // We special case a graph post to <id>/videos and send it to graph-video.facebook.com
    // We only do this for non batch post requests
    NSString *graphPath = request.graphPath.lowercaseString;
    if ([request.HTTPMethod.uppercaseString isEqualToString:@"POST"]
        && [graphPath hasSuffix:@"/videos"]) {
      graphPath = [graphPath stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"/"]];
      NSArray<NSString *> *components = [graphPath componentsSeparatedByString:@"/"];
      if (components.count == 2) {
        prefix = kGraphVideoURLPrefix;
      }
    }

    baseURL = [FBSDKInternalUtility.sharedUtility
               facebookURLWithHostPrefix:prefix
               path:request.graphPath
               queryParameters:@{}
               defaultVersion:request.version
               error:NULL].absoluteString;
  }

  NSString *url = [FBSDKGraphRequest serializeURL:baseURL
                                           params:request.parameters
                                       httpMethod:request.HTTPMethod
                                         forBatch:forBatch];
  return url;
}

#pragma mark - Private methods (response parsing)

- (void)completeFBSDKURLSessionWithResponse:(NSURLResponse *)response
                                       data:(NSData *)data
                               networkError:(NSError *)error
{
  if (self.state != FBSDKGraphRequestConnectionStateCancelled) {
    NSAssert(
      self.state == FBSDKGraphRequestConnectionStateStarted,
      @"Unexpected state %lu in completeWithResponse",
      (unsigned long)self.state
    );
    self.state = FBSDKGraphRequestConnectionStateCompleted;
  }

  NSArray<NSDictionary<NSString *, id> *> *results = nil;
  _urlResponse = (NSHTTPURLResponse *)response;
  if (response) {
    NSAssert(
      [response isKindOfClass:NSHTTPURLResponse.class],
      @"Expected NSHTTPURLResponse, got %@",
      response
    );

    NSInteger statusCode = self.urlResponse.statusCode;

    if (!error && [response.MIMEType hasPrefix:@"image"]) {
      NSString *message = @"Response is a non-text MIME type; endpoints that return images and other binary data should be fetched using NSURLRequest and NSURLSession";
      error = [self.class.errorFactory errorWithCode:FBSDKErrorGraphRequestNonTextMimeTypeReturned
                                            userInfo:nil
                                             message:message
                                     underlyingError:nil];
    } else {
      results = [self parseJSONResponse:data
                                  error:&error
                             statusCode:statusCode];
    }
  } else if (!error) {
    error = [self.class.errorFactory unknownErrorWithMessage:@"Missing NSURLResponse" userInfo:nil];
  }

  if (!error) {
    if (self.requests.count != results.count) {
      NSString *message = @"Unexpected number of results returned from server.";
      error = [self.class.errorFactory errorWithCode:FBSDKErrorGraphRequestProtocolMismatch
                                            userInfo:nil
                                             message:message
                                     underlyingError:nil];
    } else {
      [self.logger appendFormat:@"Response <#%lu>\nDuration: %llu msec\nSize: %lu kB\nResponse Body:\n%@\n\n",
       (unsigned long)self.logger.loggerSerialNumber,
       [FBSDKInternalUtility.sharedUtility currentTimeInMilliseconds] - self.requestStartTime,
       (unsigned long)data.length,
       results];
    }
  }

  if (error) {
    [self.logger appendFormat:@"Response <#%lu> <Error>:\n%@\n%@\n",
     (unsigned long)self.logger.loggerSerialNumber,
     error.localizedDescription,
     error.userInfo];
  }
  [self.logger emitToNSLog];

  [self _completeWithResults:results networkError:error];

  [self.session invalidateAndCancel];
}

//
// If there is one request, the JSON is the response.
// If there are multiple requests, the JSON has an array of dictionaries whose
// body property is the response.
// [{ "code":200,
// "body":"JSON-response-as-a-string" },
// { "code":200,
// "body":"JSON-response-as-a-string" }]
//
// In both cases, this function returns an NSArray containing the results.
// The NSArray looks just like the multiple request case except the body
// value is converted from a string to parsed JSON.
//
- (NSArray<NSDictionary<NSString *, id> *> *)parseJSONResponse:(NSData *)data
                                                         error:(NSError **)error
                                                    statusCode:(NSInteger)statusCode
{
  // Graph API can return "true" or "false", which is not valid JSON.
  // Translate that before asking JSON parser to look at it.
  NSString *responseUTF8 = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
  NSMutableArray<NSDictionary<NSString *, id> *> *_Nonnull results = [NSMutableArray new];
  id response = [self parseJSONOrOtherwise:responseUTF8 error:error];

  if (responseUTF8 == nil) {
    NSString *base64Data = data.length != 0 ? [data base64EncodedStringWithOptions:0] : @"";
    if (base64Data != nil) {
      [self.class.eventLogger logInternalEvent:@"fb_response_invalid_utf8" isImplicitlyLogged:YES];
    }
  }

  NSDictionary<NSString *, id> *responseError = nil;
  if (!response) {
    if ((error != NULL) && (*error == nil)) {
      NSString *message = @"The server returned an unexpected response.";
      NSDictionary<NSErrorUserInfoKey, id> *userInfo = @{
        FBSDKGraphRequestErrorHTTPStatusCodeKey : @(statusCode)
      };
      *error = [self.class.errorFactory unknownErrorWithMessage:message userInfo:userInfo];
    }
  } else if (self.requests.count == 1) {
    // response is the entry, so put it in a dictionary under "body" and add
    // that to array of responses.
    [FBSDKTypeUtility array:results addObject:@{
       @"code" : @(statusCode),
       @"body" : response
     }];
  } else if ([response isKindOfClass:NSArray.class]) {
    // response is the array of responses, but the body element of each needs
    // to be decoded from JSON.
    for (id item in response) {
      // Don't let errors parsing one response stop us from parsing another.
      NSError *batchResultError = nil;
      if (![item isKindOfClass:[NSDictionary<NSString *, id> class]]) {
        [FBSDKTypeUtility array:results addObject:item];
      } else {
        NSMutableDictionary<NSString *, id> *result = [((NSDictionary<NSString *, id> *)item) mutableCopy];
        if (result[@"body"]) {
          [FBSDKTypeUtility dictionary:result setObject:[self parseJSONOrOtherwise:result[@"body"] error:&batchResultError] forKey:@"body"];
        }
        [FBSDKTypeUtility array:results addObject:result];
      }
      if (batchResultError && (*error == nil)) {
        // We'll report back the last error we saw.
        *error = batchResultError;
      }
    }
  } else if ([response isKindOfClass:[NSDictionary<NSString *, id> class]]
             && (responseError = [FBSDKTypeUtility dictionaryValue:response[@"error"]]) != nil
             && [responseError[@"type"] isEqualToString:@"OAuthException"]) {
    // if there was one request then return the only result. if there were multiple requests
    // but only one error then the server rejected the batch access token
    NSDictionary<NSString *, id> *result = @{
      @"code" : @(statusCode),
      @"body" : response
    };

    for (NSUInteger resultIndex = 0, resultCount = self.requests.count; resultIndex < resultCount; ++resultIndex) {
      [FBSDKTypeUtility array:results addObject:result];
    }
  } else if (error != NULL) {
    NSDictionary<NSErrorUserInfoKey, id> *userInfo = @{
      FBSDKGraphRequestErrorHTTPStatusCodeKey : @(statusCode),
      FBSDKGraphRequestErrorParsedJSONResponseKey : results
    };
    *error = [self.class.errorFactory errorWithCode:FBSDKErrorGraphRequestProtocolMismatch
                                           userInfo:userInfo
                                            message:nil
                                    underlyingError:nil];
  }

  return results;
}

- (id)parseJSONOrOtherwise:(NSString *)unsafeString
                     error:(NSError **)error
{
  id parsed = nil;

  // Historically, people have passed-in `id` here. So, gotta double-check.
  NSString *const utf8 = _FBSDKCastToClassOrNilUnsafeInternal(unsafeString, NSString.class);
  if (!(*error) && utf8) {
    parsed = [FBSDKBasicUtility objectForJSONString:utf8 error:error];
    // if we fail parse we attempt a re-parse of a modified input to support results in the form "foo=bar", "true", etc.
    // which is shouldn't be necessary since Graph API v2.1.
    if (*error) {
      // we round-trip our hand-wired response through the parser in order to remain
      // consistent with the rest of the output of this function (note, if perf turns out
      // to be a problem -- unlikely -- we can return the following dictionary outright)
      NSError *reparseError = nil;
      parsed =
      [FBSDKBasicUtility
       objectForJSONString:
       [FBSDKBasicUtility JSONStringForObject:@{ FBSDKNonJSONResponseProperty : utf8 }
                                        error:NULL
                         invalidObjectHandler:NULL]
       error:&reparseError];

      if (!reparseError) {
        *error = nil;
      }
    }
  }
  return parsed;
}

- (void)_completeWithResults:(NSArray<NSDictionary<NSString *, id> *> *)results
                networkError:(NSError *)networkError
{
  NSUInteger count = self.requests.count;
  self.expectingResults = count;
  NSUInteger disabledRecoveryCount = 0;
  for (FBSDKGraphRequestMetadata *metadata in self.requests) {
    if ([metadata.request isGraphErrorRecoveryDisabled]) {
      disabledRecoveryCount++;
    }
  }
#if !TARGET_OS_TV
  BOOL isSingleRequestToRecover = (count - disabledRecoveryCount == 1);
#endif

  [self.requests enumerateObjectsUsingBlock:^(FBSDKGraphRequestMetadata *metadata, NSUInteger i, BOOL *stop) {
    id result = networkError ? nil : [FBSDKTypeUtility array:results objectAtIndex:i];
    NSError *const resultError = networkError ?: [self errorFromResult:result request:metadata.request];

    id body = nil;
    if (!resultError && [result isKindOfClass:[NSDictionary<NSString *, id> class]]) {
      NSDictionary<NSString *, id> *resultDictionary = [FBSDKTypeUtility dictionaryValue:result];
      body = [FBSDKTypeUtility dictionaryValue:resultDictionary[@"body"]];
    }

  #if !TARGET_OS_TV
    BOOL isRecoveryDisabled = [metadata.request isGraphErrorRecoveryDisabled];
    if (resultError && !isRecoveryDisabled && isSingleRequestToRecover) {
      self->_recoveringRequestMetadata = metadata;
      self->_errorRecoveryProcessor = [[FBSDKGraphErrorRecoveryProcessor alloc]
                                       initWithAccessTokenString:[[self.class.accessTokenProvider currentAccessToken] tokenString]];
      if ([self->_errorRecoveryProcessor processError:resultError request:metadata.request delegate:self]) {
        return;
      }
    }
  #endif

    [self processResultBody:body error:resultError metadata:metadata canNotifyDelegate:networkError == nil];
  }];

  if (networkError) {
    if ([self.delegate respondsToSelector:@selector(requestConnection:didFailWithError:)]) {
      [self.delegate requestConnection:self didFailWithError:networkError];
    }
  }
}

- (void)processResultBody:(NSDictionary<NSString *, id> *)body error:(NSError *)error metadata:(FBSDKGraphRequestMetadata *)metadata canNotifyDelegate:(BOOL)canNotifyDelegate
{
  void (^finishAndInvokeCompletionHandler)(void) = ^{
    NSDictionary<NSString *, id> *graphDebugDict = body[@"__debug__"];
    if ([graphDebugDict isKindOfClass:[NSDictionary<NSString *, id> class]]) {
      [self processResultDebugDictionary:graphDebugDict];
    }
    [metadata invokeCompletionHandlerForConnection:self withResults:body error:error];

    if (--self->_expectingResults == 0) {
      if (canNotifyDelegate && [self->_delegate respondsToSelector:@selector(requestConnectionDidFinishLoading:)]) {
        [self->_delegate requestConnectionDidFinishLoading:self];
      }
    }
  };

#if !TARGET_OS_TV
  void (^clearToken)(NSInteger) = ^(NSInteger errorSubcode) {
    FBSDKGraphRequestFlags flags = [metadata.request flags];
    if (flags & FBSDKGraphRequestFlagDoNotInvalidateTokenOnError) {
      return;
    }
    if (errorSubcode == 493) {
      [self.class.accessTokenSetter setCurrentAccessToken:_CreateExpiredAccessToken([self.class.accessTokenProvider currentAccessToken])];
    } else {
      [self.class.accessTokenSetter setCurrentAccessToken:nil];
    }
  };

  NSString *metadataTokenString = metadata.request.tokenString;
  NSString *currentTokenString = [[self.class.accessTokenProvider currentAccessToken] tokenString];

  if ([metadataTokenString isEqualToString:currentTokenString]) {
    NSInteger errorCode = [error.userInfo[FBSDKGraphRequestErrorGraphErrorCodeKey] integerValue];
    NSInteger errorSubcode = [error.userInfo[FBSDKGraphRequestErrorGraphErrorSubcodeKey] integerValue];
    if (errorCode == 190 || errorCode == 102) {
      clearToken(errorSubcode);
    }
  }
#endif
  // this is already on the queue since we are currently in the NSURLSession callback.
  finishAndInvokeCompletionHandler();
}

- (void)processResultDebugDictionary:(NSDictionary<NSString *, id> *)dict
{
  NSArray<NSDictionary<NSString *, id> *> *messages = [FBSDKTypeUtility arrayValue:dict[@"messages"]];
  if (!messages.count) {
    return;
  }

  [messages enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
    NSDictionary<NSString *, id> *messageDict = [FBSDKTypeUtility dictionaryValue:obj];
    NSString *message = [FBSDKTypeUtility coercedToStringValue:messageDict[@"message"]];
    NSString *type = [FBSDKTypeUtility coercedToStringValue:messageDict[@"type"]];
    NSString *link = [FBSDKTypeUtility coercedToStringValue:messageDict[@"link"]];
    if (!message || !type) {
      return;
    }

    NSString *loggingBehavior = FBSDKLoggingBehaviorGraphAPIDebugInfo;
    if ([type isEqualToString:@"warning"]) {
      loggingBehavior = FBSDKLoggingBehaviorGraphAPIDebugWarning;
    }
    if (link) {
      message = [message stringByAppendingFormat:@" Link: %@", link];
    }

    [self.logger.class singleShotLogEntry:loggingBehavior logEntry:message];
  }];
}

- (nullable NSError *)errorFromResult:(id)untypedParam request:(id<FBSDKGraphRequest>)request
{
  NSDictionary<NSString *, id> *const result = _FBSDKCastToClassOrNilUnsafeInternal(untypedParam, NSDictionary.class);
  if (!result) {
    return nil;
  }

  NSDictionary<NSString *, id> *const body = _FBSDKCastToClassOrNilUnsafeInternal(result[@"body"], NSDictionary.class);
  if (!body) {
    return nil;
  }

  NSDictionary<NSString *, id> *const errorDictionary = _FBSDKCastToClassOrNilUnsafeInternal(body[@"error"], NSDictionary.class);
  if (!errorDictionary) {
    return nil;
  }

  NSMutableDictionary<NSErrorUserInfoKey, id> *userInfo = [NSMutableDictionary dictionary];

  NSNumber *errorCodeNumber = [FBSDKTypeUtility numberValue:errorDictionary[@"code"]];
  NSString *errorCodeString = [errorCodeNumber stringValue] ?: @"*";
  [FBSDKTypeUtility dictionary:userInfo
                     setObject:errorCodeNumber
                        forKey:FBSDKGraphRequestErrorGraphErrorCodeKey];

  NSNumber *errorSubcodeNumber = [FBSDKTypeUtility numberValue:errorDictionary[@"error_subcode"]];
  NSString *errorSubcodeString = [errorSubcodeNumber stringValue] ?: @"*";
  [FBSDKTypeUtility dictionary:userInfo
                     setObject:errorSubcodeNumber
                        forKey:FBSDKGraphRequestErrorGraphErrorSubcodeKey];

  [FBSDKTypeUtility dictionary:userInfo
                     setObject:errorDictionary[@"error_user_title"]
                        forKey:FBSDKErrorLocalizedTitleKey];
  [FBSDKTypeUtility dictionary:userInfo
                     setObject:errorDictionary[@"error_user_msg"]
                        forKey:FBSDKErrorLocalizedDescriptionKey];
  [FBSDKTypeUtility dictionary:userInfo
                     setObject:errorDictionary[@"error_user_msg"]
                        forKey:NSLocalizedDescriptionKey];
  [FBSDKTypeUtility dictionary:userInfo
                     setObject:result[@"code"]
                        forKey:FBSDKGraphRequestErrorHTTPStatusCodeKey];
  [FBSDKTypeUtility dictionary:userInfo
                     setObject:result
                        forKey:FBSDKGraphRequestErrorParsedJSONResponseKey];

  id<FBSDKErrorConfiguration> errorConfiguration = self.class.errorConfigurationProvider.errorConfiguration;
  FBSDKErrorRecoveryConfiguration *recoveryConfiguration = [errorConfiguration recoveryConfigurationForCode:errorCodeString
                                                                                                    subcode:errorSubcodeString
                                                                                                    request:request];

  BOOL isTransient = [[FBSDKTypeUtility numberValue:errorDictionary[@"is_transient"]] boolValue];
  NSNumber *errorCategory = isTransient ? @(FBSDKGraphRequestErrorTransient) : @(recoveryConfiguration.errorCategory);
  [FBSDKTypeUtility dictionary:userInfo
                     setObject:errorCategory
                        forKey:FBSDKGraphRequestErrorKey];

  [FBSDKTypeUtility dictionary:userInfo
                     setObject:recoveryConfiguration.localizedRecoveryDescription
                        forKey:NSLocalizedRecoverySuggestionErrorKey];
  [FBSDKTypeUtility dictionary:userInfo
                     setObject:recoveryConfiguration.localizedRecoveryOptionDescriptions
                        forKey:NSLocalizedRecoveryOptionsErrorKey];

  FBSDKErrorRecoveryAttempter *attempter = [FBSDKErrorRecoveryAttempter recoveryAttempterFromConfiguration:recoveryConfiguration];
  [FBSDKTypeUtility dictionary:userInfo setObject:attempter forKey:NSRecoveryAttempterErrorKey];

  // Getting the message from "message" which is preferred over "error_msg"
  // which is itself preferred over "error_reason".
  NSString *message = _FBSDKCastToClassOrNilUnsafeInternal(errorDictionary[@"message"], NSString.class)
  ?: _FBSDKCastToClassOrNilUnsafeInternal(errorDictionary[@"error_reason"], NSString.class)
    ?: _FBSDKCastToClassOrNilUnsafeInternal(errorDictionary[@"error_msg"], NSString.class);

  return [self.class.errorFactory errorWithCode:FBSDKErrorGraphRequestGraphAPI
                                       userInfo:userInfo
                                        message:message
                                underlyingError:nil];
}

#pragma mark - Private methods (logging and completion)

- (void)logAndInvokeHandler:(FBSDKURLSessionTaskBlock)handler
                      error:(NSError *)error
{
  if (error) {
    NSString *logEntry = [NSString
                          stringWithFormat:@"FBSDKURLSessionTask <#%lu>:\n  Error: '%@'\n%@\n",
                          (unsigned long)[FBSDKLogger generateSerialNumber],
                          error.localizedDescription,
                          error.userInfo];

    [self logMessage:logEntry];
  }

  [self invokeHandler:handler error:error response:nil responseData:nil];
}

- (void)logAndInvokeHandler:(FBSDKURLSessionTaskBlock)handler
                   response:(NSURLResponse *)response
               responseData:(NSData *)responseData
           requestStartTime:(uint64_t)requestStartTime
{
  // Basic logging just prints out the URL.  FBSDKGraphRequest logging provides more details.
  NSString *mimeType = response.MIMEType;
  NSMutableString *mutableLogEntry = [NSMutableString stringWithFormat:@"FBSDKGraphRequestConnection <#%lu>:\n  Duration: %llu msec\nResponse Size: %lu kB\n  MIME type: %@\n",
                                      (unsigned long)[FBSDKLogger generateSerialNumber],
                                      [FBSDKInternalUtility.sharedUtility currentTimeInMilliseconds] - requestStartTime,
                                      (unsigned long)responseData.length / 1024,
                                      mimeType];

  if ([mimeType isEqualToString:@"text/javascript"]) {
    NSString *responseUTF8 = [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding];
    [mutableLogEntry appendFormat:@"  Response:\n%@\n\n", responseUTF8];
  }

  [self logMessage:mutableLogEntry];

  [self invokeHandler:handler error:nil response:response responseData:responseData];
}

- (void)invokeHandler:(FBSDKURLSessionTaskBlock)handler
                error:(NSError *)error
             response:(NSURLResponse *)response
         responseData:(NSData *)responseData
{
  if (handler != nil) {
    dispatch_async(dispatch_get_main_queue(), ^{
      handler(responseData, response, error);
    });
  }
}

- (void)logMessage:(NSString *)message
{
  [FBSDKLogger singleShotLogEntry:FBSDKLoggingBehaviorNetworkRequests logEntry:message];
}

- (void)taskDidCompleteWithResponse:(NSURLResponse *)response
                               data:(NSData *)data
                   requestStartTime:(uint64_t)requestStartTime
                            handler:(FBSDKURLSessionTaskBlock)handler
{
  @try {
    [self logAndInvokeHandler:handler
                     response:response
                 responseData:data
             requestStartTime:requestStartTime];
  } @finally {}
}

#pragma mark - Private methods (miscellaneous)

- (void)_taskDidCompleteWithError:(NSError *)error
                          handler:(FBSDKURLSessionTaskBlock)handler
{
  @try {
    if ([error.domain isEqualToString:NSURLErrorDomain] && error.code == kCFURLErrorSecureConnectionFailed) {
      [FBSDKLogger singleShotLogEntry:FBSDKLoggingBehaviorDeveloperErrors
                             logEntry:@"WARNING: FBSDK secure network request failed. Please verify you have followed "
       "all of the steps at https://developers.facebook.com/docs/ios/getting-started"];
    }
    [self logAndInvokeHandler:handler error:error];
  } @finally {}
}

- (void)logRequest:(NSMutableURLRequest *)request
        bodyLength:(NSUInteger)bodyLength
        bodyLogger:(FBSDKLogger *)bodyLogger
  attachmentLogger:(FBSDKLogger *)attachmentLogger
{
  if (self.logger.isActive) {
    [self.logger appendFormat:@"Request <#%lu>:\n", (unsigned long)self.logger.loggerSerialNumber];
    [self.logger appendKey:@"URL" value:request.URL.absoluteString];
    [self.logger appendKey:@"Method" value:request.HTTPMethod];
    NSString *userAgent = [request valueForHTTPHeaderField:@"User-Agent"];
    if (userAgent) {
      [self.logger appendKey:@"UserAgent" value:userAgent];
    }
    NSString *mimeType = [request valueForHTTPHeaderField:@"Content-Type"];
    if (mimeType) {
      [self.logger appendKey:@"MIME" value:mimeType];
    }

    if (bodyLength != 0) {
      [self.logger appendKey:@"Body Size" value:[NSString stringWithFormat:@"%lu kB", (unsigned long)bodyLength / 1024]];
    }

    if (bodyLogger != nil) {
      [self.logger appendKey:@"Body (w/o attachments)" value:bodyLogger.contents];
    }

    if (attachmentLogger != nil) {
      [self.logger appendKey:@"Attachments" value:attachmentLogger.contents];
    }

    [self.logger appendString:@"\n"];

    [self.logger emitToNSLog];
  }
}

- (NSString *)accessTokenWithRequest:(id<FBSDKGraphRequest>)request
{
  [self raiseExceptionIfMissingClientToken];

  NSString *token = request.tokenString ?: request.parameters[kAccessTokenKey];
  FBSDKGraphRequestFlags flags = [request flags];
  if (!token && !(flags & FBSDKGraphRequestFlagSkipClientToken) && [self.class.settings.clientToken length] > 0) {
    NSString *baseTokenString = [NSString stringWithFormat:@"%@|%@", self.class.settings.appID, self.class.settings.clientToken];
    if ([[[self.class.authenticationTokenProvider currentAuthenticationToken] graphDomain] isEqualToString:@"gaming"]) {
      return [@"GG|" stringByAppendingString:baseTokenString];
    } else {
      return baseTokenString;
    }
  }
  return token;
}

- (void)registerTokenToOmitFromLog:(NSString *)token
{
  if (![self.class.settings.loggingBehaviors containsObject:FBSDKLoggingBehaviorAccessTokens]) {
    [FBSDKLogger registerStringToReplace:token replaceWith:@"ACCESS_TOKEN_REMOVED"];
  }
}

- (void)raiseExceptionIfMissingClientToken
{
  if (!self.class.settings.clientToken) {
    NSString *reason =
    [NSString stringWithFormat:
     @"Starting with v13 of the SDK, a client token must be embedded in your client code before making Graph API calls.\n"
     "Visit https://developers.facebook.com/apps/%@/settings/advanced/ to find your client token for this app.\n"
     "Add a key named FacebookClientToken to your Info.plist, and add your client token as its value.\n"
     "Visit https://developers.facebook.com/docs/ios/getting-started#configure-your-project for more information.",
     self.class.settings.appID];

    [self.logger.class singleShotLogEntry:FBSDKLoggingBehaviorDeveloperErrors
                                 logEntry:reason];

    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:reason
                                 userInfo:nil];
  }
}

- (NSString *)userAgent
{
  static NSString *agent = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    agent = [NSString stringWithFormat:@"%@.%@", kUserAgentBase, FBSDK_VERSION_STRING];
  });
  NSString *agentWithSuffix = nil;
  if (self.class.settings.userAgentSuffix) {
    agentWithSuffix = [NSString stringWithFormat:@"%@/%@", agent, self.class.settings.userAgentSuffix];
  }
  if (@available(iOS 13.0, *)) {
    if (self.class.macCatalystDeterminator.isMacCatalystApp) {
      return [NSString stringWithFormat:@"%@/%@", agentWithSuffix ?: agent, @"macOS"];
    }
  }

  return agentWithSuffix ?: agent;
}

#pragma mark - NSURLSessionDataDelegate

- (void)        URLSession:(NSURLSession *)session
                      task:(NSURLSessionTask *)task
           didSendBodyData:(int64_t)bytesSent
            totalBytesSent:(int64_t)totalBytesSent
  totalBytesExpectedToSend:(int64_t)totalBytesExpectedToSend
{
  id<FBSDKGraphRequestConnectionDelegate> delegate = self.delegate;

  if ([delegate respondsToSelector:@selector(requestConnection:didSendBodyData:totalBytesWritten:totalBytesExpectedToWrite:)]) {
    [delegate requestConnection:self
                didSendBodyData:(NSUInteger)bytesSent
              totalBytesWritten:(NSUInteger)totalBytesSent
      totalBytesExpectedToWrite:(NSUInteger)totalBytesExpectedToSend];
  }
}

#pragma mark - FBSDKGraphErrorRecoveryProcessorDelegate

#if !TARGET_OS_TV
- (void)processorDidAttemptRecovery:(FBSDKGraphErrorRecoveryProcessor *)processor didRecover:(BOOL)didRecover error:(NSError *)error
{
  @try {
    if (didRecover) {
      id<FBSDKGraphRequest> originalRequest = self.recoveringRequestMetadata.request;
      id<FBSDKGraphRequest> retryRequest = [[FBSDKGraphRequest alloc] initWithGraphPath:originalRequest.graphPath
                                                                             parameters:originalRequest.parameters
                                                                            tokenString:[[self.class.accessTokenProvider currentAccessToken] tokenString]
                                                                             HTTPMethod:originalRequest.HTTPMethod
                                                                                version:originalRequest.version
                                                                                  flags:FBSDKGraphRequestFlagDisableErrorRecovery
                                                          graphRequestConnectionFactory:self.class.graphRequestConnectionFactory];
      FBSDKGraphRequestMetadata *retryMetadata = [[FBSDKGraphRequestMetadata alloc] initWithRequest:retryRequest completionHandler:self.recoveringRequestMetadata.completionHandler batchParameters:self.recoveringRequestMetadata.batchParameters];
      [retryRequest startWithCompletion:^(id<FBSDKGraphRequestConnecting> potentialConnection, id result, NSError *retriedError) {
        [self processResultBody:result error:retriedError metadata:retryMetadata canNotifyDelegate:YES];
        self->_errorRecoveryProcessor = nil;
        self->_recoveringRequestMetadata = nil;
      }];
    } else {
      [self processResultBody:nil error:error metadata:self.recoveringRequestMetadata canNotifyDelegate:YES];
      self.errorRecoveryProcessor = nil;
      self.recoveringRequestMetadata = nil;
    }
  } @catch (NSException *exception) {}
}

#endif

#pragma mark - Debugging helpers

- (NSString *)description
{
  NSMutableString *result = [NSMutableString stringWithFormat:@"<%@: %p, %lu request(s): (\n",
                             NSStringFromClass(self.class),
                             self,
                             (unsigned long)self.requests.count];
  BOOL comma = NO;
  for (FBSDKGraphRequestMetadata *metadata in self.requests) {
    id<FBSDKGraphRequest> request = metadata.request;
    if (comma) {
      [result appendString:@",\n"];
    }
    [result appendString:request.formattedDescription];
    comma = YES;
  }
  [result appendString:@"\n)>"];
  return result;
}

// MARK: - Testability

#if DEBUG

/// Resets the default connection timeout to 60 seconds
+ (void)resetDefaultConnectionTimeout
{
  g_defaultTimeout = 60;
}

+ (void)resetCanMakeRequests
{
  _canMakeRequests = NO;
}

#endif

@end
