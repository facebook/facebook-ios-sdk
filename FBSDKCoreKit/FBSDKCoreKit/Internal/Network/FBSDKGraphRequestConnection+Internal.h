/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <FBSDKCoreKit/FBSDKCoreKit.h>

#import "FBSDKEventLogging.h"
#import "FBSDKGraphErrorRecoveryProcessor.h"
#import "FBSDKGraphRequestBody.h"
#import "FBSDKGraphRequestMetadata.h"
#import "FBSDKURLSessionProxying.h"

NS_ASSUME_NONNULL_BEGIN

// ----------------------------------------------------------------------------
// FBSDKGraphRequestConnectionState

typedef NS_ENUM(NSUInteger, FBSDKGraphRequestConnectionState) {
  FBSDKGraphRequestConnectionStateCreated,
  FBSDKGraphRequestConnectionStateSerialized,
  FBSDKGraphRequestConnectionStateStarted,
  FBSDKGraphRequestConnectionStateCompleted,
  FBSDKGraphRequestConnectionStateCancelled,
} NS_SWIFT_NAME(GraphRequestConnectionState);

@interface FBSDKGraphRequestConnection ()

@property (class, nullable, nonatomic) id<FBSDKURLSessionProxyProviding> sessionProxyFactory;
@property (class, nullable, nonatomic) id<FBSDKErrorConfigurationProviding> errorConfigurationProvider;
@property (class, nullable, nonatomic) id<FBSDKGraphRequestPiggybackManaging> piggybackManager;
@property (class, nullable, nonatomic) id<FBSDKSettings> settings;
@property (class, nullable, nonatomic) id<FBSDKGraphRequestConnectionFactory> graphRequestConnectionFactory;
@property (class, nullable, nonatomic) id<FBSDKEventLogging> eventLogger;
@property (class, nullable, nonatomic) id<FBSDKOperatingSystemVersionComparing> operatingSystemVersionComparer;
@property (class, nullable, nonatomic) id<FBSDKMacCatalystDetermining> macCatalystDeterminator;
@property (class, nullable, nonatomic) Class<FBSDKAccessTokenProviding> accessTokenProvider;
@property (class, nullable, nonatomic) id<FBSDKErrorCreating> errorFactory;
@property (class, nullable, nonatomic) Class<FBSDKAuthenticationTokenProviding> authenticationTokenProvider;
@property (nonatomic) FBSDKLogger *logger;
@property (nonatomic) NSMutableArray<FBSDKGraphRequestMetadata *> *requests;
@property (nonatomic) FBSDKGraphRequestConnectionState state;
@property (nonatomic) uint64_t requestStartTime;
@property (nonatomic) id<FBSDKURLSessionProxying> session;
@property (nullable, nonatomic) NSString *overriddenVersionPart;
@property (nonatomic) NSUInteger expectingResults;
#if !TARGET_OS_TV
@property (nullable, nonatomic) FBSDKGraphRequestMetadata *recoveringRequestMetadata;
@property (nullable, nonatomic) FBSDKGraphErrorRecoveryProcessor *errorRecoveryProcessor;
#endif

+ (BOOL)canMakeRequests;
+ (BOOL)didFetchDomainConfiguration;

- (NSMutableURLRequest *)requestWithBatch:(NSArray<FBSDKGraphRequestMetadata *> *)requests
                                  timeout:(NSTimeInterval)timeout;

- (void)addRequest:(FBSDKGraphRequestMetadata *)metadata
           toBatch:(NSMutableArray<NSMutableDictionary<NSString *, id> *> *)batch
       attachments:(NSMutableDictionary<NSString *, id> *)attachments
        batchToken:(nullable NSString *)batchToken;

- (void)appendAttachments:(NSDictionary<NSString *, id> *)attachments
                   toBody:(FBSDKGraphRequestBody *)body
              addFormData:(BOOL)addFormData
                   logger:(FBSDKLogger *)logger;

- (nullable NSString *)accessTokenWithRequest:(id<FBSDKGraphRequest>)request;

- (nullable NSError *)errorFromResult:(id)untypedParam request:(id<FBSDKGraphRequest>)request;

- (NSArray<id> *)parseJSONResponse:(NSData *)data
                             error:(NSError **)error
                        statusCode:(NSInteger)statusCode;

- (void)processResultBody:(nullable NSDictionary<NSString *, id> *)body
                    error:(nullable NSError *)error
                 metadata:(FBSDKGraphRequestMetadata *)metadata
        canNotifyDelegate:(BOOL)canNotifyDelegate;

- (void)logRequest:(NSMutableURLRequest *)request
        bodyLength:(NSUInteger)bodyLength
        bodyLogger:(nullable FBSDKLogger *)bodyLogger
  attachmentLogger:(nullable FBSDKLogger *)attachmentLogger;

- (void)        URLSession:(NSURLSession *)session
                      task:(NSURLSessionTask *)task
           didSendBodyData:(int64_t)bytesSent
            totalBytesSent:(int64_t)totalBytesSent
  totalBytesExpectedToSend:(int64_t)totalBytesExpectedToSend;

/**
 Get the graph request url for a single, stand-alone graph request
 @param request The Graph Request we need the url for
 */
- (NSString *)urlStringForSingleRequest:(id<FBSDKGraphRequest>)request;

/**
 Get the graph request url for a single graph request that belongs to a batch
 @param request The Graph Request we need the url for
 */
- (NSString *)urlStringForRequestInBatch:(id<FBSDKGraphRequest>)request;

/**
 Add the specified body as the HTTPBody of the specified request.
 @param body The FBSDKGraphRequestBody to attach to the request.
 @param request The NSURLRequest to attach the body to.
 */
- (void)addBody:(FBSDKGraphRequestBody *)body toPostRequest:(NSMutableURLRequest *)request;

#if DEBUG
+ (void)resetClassDependencies;
#endif

@end

NS_ASSUME_NONNULL_END
