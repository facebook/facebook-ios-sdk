/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "FBSDKTimeSpentRecordingFactory.h"

#import "FBSDKEventLogging.h"
#import "FBSDKServerConfigurationProviding.h"
#import "FBSDKTimeSpentData.h"
#import "FBSDKTimeSpentData+SourceApplicationTracking.h"
#import "FBSDKTimeSpentData+TimeSpentRecording.h"

NS_ASSUME_NONNULL_BEGIN

@interface FBSDKTimeSpentRecordingFactory ()

@property (nonnull, nonatomic, readonly) id<FBSDKServerConfigurationProviding> serverConfigurationProvider;
@property (nonnull, nonatomic, readonly) id<FBSDKEventLogging> eventLogger;

@end

@implementation FBSDKTimeSpentRecordingFactory

- (instancetype)initWithEventLogger:(id<FBSDKEventLogging>)eventLogger
        serverConfigurationProvider:(id<FBSDKServerConfigurationProviding>)serverConfigurationProvider
{
  if ((self = [super init])) {
    _eventLogger = eventLogger;
    _serverConfigurationProvider = serverConfigurationProvider;
  }
  return self;
}

- (id<FBSDKSourceApplicationTracking, FBSDKTimeSpentRecording>)createTimeSpentRecorder
{
  return [[FBSDKTimeSpentData alloc] initWithEventLogger:self.eventLogger
                             serverConfigurationProvider:self.serverConfigurationProvider];
}

@end

NS_ASSUME_NONNULL_END
