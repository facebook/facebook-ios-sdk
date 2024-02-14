/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "FBSDKInternalUtility+Internal.h"
#import "FBSDKGraphRequestQueue.h"
#import "FBSDKLogger+Internal.h"

@interface FBSDKGraphRequestQueue ()

@property (nonatomic, strong) NSMutableArray<FBSDKGraphRequestMetadata *> *requestsQueue;
@property (nullable, nonatomic, strong) id<FBSDKGraphRequestConnectionFactory> graphRequestConnectionFactory;
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
{
  self.graphRequestConnectionFactory = graphRequestConnectionFactory;
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
  [self.requestsQueue removeAllObjects];
}

#endif

@end
