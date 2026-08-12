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

@interface FBSDKGraphRequestQueue ()

@property (nonatomic, strong) NSMutableArray<FBSDKGraphRequestMetadata *> *requestsQueue;
@property (nullable, nonatomic, strong) id<FBSDKGraphRequestConnectionFactory> graphRequestConnectionFactory;
@property (nullable, nonatomic, weak) id<FBSDKSettings> settings;
@property (nonatomic, strong) FBSDKLogger *logger;

@end

@implementation FBSDKGraphRequestQueue

- (instancetype)init
{
  if (self = [super init]) {
    _requestsQueue = [NSMutableArray new];
    _logger = [[FBSDKLogger alloc] initWithLoggingBehavior:FBSDKLoggingBehaviorNetworkRequests];
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
  @synchronized (self) {
    [self logEnqueueRequest:requestMetadata.request];
    [FBSDKTypeUtility array:self.requestsQueue addObject:requestMetadata];
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
    id<FBSDKGraphRequestConnecting> requestConnection = [self.graphRequestConnectionFactory createGraphRequestConnection];
    for (FBSDKGraphRequestMetadata *metadata in requestsToFlush) {
      [requestConnection addRequest:metadata.request completion:metadata.completionHandler];
    }
    [self logFlushingRequests:requestsToFlush];
    [requestConnection start];
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
