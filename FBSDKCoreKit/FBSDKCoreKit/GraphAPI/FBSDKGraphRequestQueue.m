/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <FBSDKCoreKit/FBSDKCoreKit-Swift.h>

#import "FBSDKInternalUtility+Internal.h"
#import "FBSDKGraphRequestQueue.h"
#import "FBSDKLogger+Internal.h"

/// The Graph API rejects a batch of more than 50 sub-requests outright, with no partial results.
static const NSUInteger kMaxRequestsPerBatch = 50;

/// Upper bound on the queue so a queue that never opens cannot grow without limit.
static const NSUInteger kMaxQueuedRequests = 1000;

@interface FBSDKGraphRequestQueue ()

@property (nonatomic, strong) NSMutableArray<FBSDKGraphRequestMetadata *> *requestsQueue;
@property (nullable, nonatomic, strong) id<FBSDKGraphRequestConnectionFactory> graphRequestConnectionFactory;
@property (nullable, nonatomic, weak) id<FBSDKSettings> settings;
@property (nonatomic, strong) FBSDKLogger *logger;
@property (nonatomic, strong) id<FBSDKErrorCreating> errorFactory;
@property (nonatomic) NSUInteger numDroppedRequests;

@end

@implementation FBSDKGraphRequestQueue

- (instancetype)init
{
  if (self = [super init]) {
    _requestsQueue = [NSMutableArray new];
    _logger = [[FBSDKLogger alloc] initWithLoggingBehavior:FBSDKLoggingBehaviorNetworkRequests];
    _errorFactory = [FBSDKErrorFactory new];
  }
  return self;
}

+ (instancetype)sharedInstance
{
  static FBSDKGraphRequestQueue *instance = nil;
  static dispatch_once_t onceToken = 0;
  dispatch_once(&onceToken, ^{
    instance = [FBSDKGraphRequestQueue new];
  });
  return instance;
}

- (void)configureWithGraphRequestConnectionFactory:(id<FBSDKGraphRequestConnectionFactory>)graphRequestConnectionFactory
                                          settings:(nullable id<FBSDKSettings>)settings
{
  self.graphRequestConnectionFactory = graphRequestConnectionFactory;
  self.settings = settings;
}

- (void)configureWithGraphRequestConnectionFactory:(id<FBSDKGraphRequestConnectionFactory>)graphRequestConnectionFactory
{
  // Settings must be non-nil: `canFlushRequests` reads `appID` and `clientToken` from it, and a
  // nil leaves the queue permanently unable to flush.
  [self configureWithGraphRequestConnectionFactory:graphRequestConnectionFactory
                                          settings:FBSDKSettings.sharedSettings];
}

- (void)enqueueRequest:(id<FBSDKGraphRequest>)request
        completion:(FBSDKGraphRequestCompletion)completion
{
  FBSDKGraphRequestMetadata *metadata = [[FBSDKGraphRequestMetadata alloc] initWithRequest:request
                                                                         completionHandler:completion
                                                                           batchParameters:nil];
  [self enqueueRequestMetadata:metadata];
}

- (void)enqueueRequests:(NSArray<FBSDKGraphRequestMetadata *> *)requests
{
  for (FBSDKGraphRequestMetadata *metadata in requests) {
    [self enqueueRequestMetadata:metadata];
  }
}

- (void)enqueueRequestMetadata:(FBSDKGraphRequestMetadata *)requestMetadata
{
  NSUInteger droppedTotal = 0;
  @synchronized (self) {
    if (self.requestsQueue.count < kMaxQueuedRequests) {
      [self logEnqueueRequest:requestMetadata.request];
      [FBSDKTypeUtility array:self.requestsQueue addObject:requestMetadata];
      return;
    }
    self.numDroppedRequests += 1;
    droppedTotal = self.numDroppedRequests;
  }

  // A dropped request is never sent, so its completion must be invoked here -- the flush path,
  // which normally invokes it via `addRequest:completion:`, will never see this request. Delivery
  // is dispatched to the main queue to match how a completed request's handler is invoked, and so
  // that the handler runs after the caller has finished submitting rather than part way through it.
  // The connection argument is nil because no connection was ever created for this request.
  NSString *msg = [NSString stringWithFormat:
                   @"FBSDKGraphRequestQueue full (%lu); dropping request. Total dropped: %lu",
                   (unsigned long)kMaxQueuedRequests, (unsigned long)droppedTotal];
  [self.logger.class singleShotLogEntry:FBSDKLoggingBehaviorDeveloperErrors logEntry:msg];
  FBSDKGraphRequestCompletion completionHandler = requestMetadata.completionHandler;
  if (completionHandler) {
    NSError *error = [self.errorFactory unknownErrorWithMessage:msg userInfo:nil];
    dispatch_async(dispatch_get_main_queue(), ^{
      completionHandler(nil, nil, error);
    });
  }
}

- (void)flush
{
  @synchronized (self) {
    if (self.requestsQueue.count == 0) {
      return;
    }
    // Do not flush until the SDK is configured to make requests. Issuing a batch (or single) graph
    // request without an app ID / client token raises an exception, so keep the requests queued and
    // flush them once a valid configuration is set (e.g. FacebookAppID at launch, or a later
    // Settings.appID / Settings.clientToken assignment, which re-invokes flush).
    if (![self canFlushRequests]) {
      return;
    }
    NSArray<FBSDKGraphRequestMetadata *> *requestsToFlush = [self.requestsQueue copy];
    [self.requestsQueue removeAllObjects];
    [self logFlushingRequests:requestsToFlush];

    NSUInteger total = requestsToFlush.count;
    for (NSUInteger offset = 0; offset < total; offset += kMaxRequestsPerBatch) {
      NSUInteger length = MIN(kMaxRequestsPerBatch, total - offset);
      NSArray<FBSDKGraphRequestMetadata *> *chunk = [requestsToFlush subarrayWithRange:NSMakeRange(offset, length)];
      id<FBSDKGraphRequestConnecting> requestConnection = [self.graphRequestConnectionFactory createGraphRequestConnection];
      for (FBSDKGraphRequestMetadata *metadata in chunk) {
        [requestConnection addRequest:metadata.request completion:metadata.completionHandler];
      }
      [requestConnection start];
    }
  }
}

- (BOOL)canFlushRequests
{
  // A batch request requires an app ID, and a token-less request requires a client token; without
  // both, starting the connection raises. Treat the SDK as flushable only when both are present.
  return self.settings.appID.length > 0 && self.settings.clientToken.length > 0;
}

- (void)logEnqueueRequest:(id<FBSDKGraphRequest>)request
{
  if (self.logger.isActive) {
    [self.logger appendString:@"FBSDKGraphRequestQueue Enqueue Request\n"];
    [self.logger appendKey:@"Method" value:request.HTTPMethod];
    [self.logger appendKey:@"Graph Path" value:[NSString stringWithFormat:@"/%@", request.graphPath]];
    [self.logger appendKey:@"Parameters" value:[request.parameters description]];
    [self.logger appendString:@"\n"];
    [self.logger emitToNSLog];
  }
}

- (void)logFlushingRequests:(NSArray<FBSDKGraphRequestMetadata *> *)requests
{
  if (self.logger.isActive) {
    [self.logger appendString:@"FBSDKGraphRequestQueue Flush Requests\n"];
    [self.logger appendFormat:@"Flushing %lu request(s):\n", (unsigned long)requests.count];
    for (FBSDKGraphRequestMetadata *metadata in requests) {
      NSDictionary *loggingInfo = @{
        @"Method": metadata.request.HTTPMethod,
        @"Graph Path": [NSString stringWithFormat:@"/%@", metadata.request.graphPath],
        @"Parameters": [metadata.request.parameters description]
      };
      [self.logger appendFormat:@"%@\n", [loggingInfo description]];
    }
    [self.logger emitToNSLog];
  }
}

#if DEBUG

- (void)reset
{
  self.graphRequestConnectionFactory = nil;
  self.settings = nil;
  [self.requestsQueue removeAllObjects];
}

#endif

@end
