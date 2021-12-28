/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "FBSDKImpressionLoggingButton+Internal.h"

#import "FBSDKButtonImpressionLogging.h"

@implementation FBSDKImpressionLoggingButton

static id<FBSDKImpressionLoggerFactory> _impressionLoggerFactory;

+ (nullable id<FBSDKImpressionLoggerFactory>)impressionLoggerFactory
{
  return _impressionLoggerFactory;
}

+ (void)setImpressionLoggerFactory:(nullable id<FBSDKImpressionLoggerFactory>)impressionLoggerFactory
{
  _impressionLoggerFactory = impressionLoggerFactory;
}

+ (void)configureWithImpressionLoggerFactory:(id<FBSDKImpressionLoggerFactory>)impressionLoggerFactory
{
  self.impressionLoggerFactory = impressionLoggerFactory;
}

- (void)layoutSubviews
{
  // automatic impression tracking if the button conforms to FBSDKButtonImpressionTracking
  if ([self conformsToProtocol:@protocol(FBSDKButtonImpressionLogging)]) {
    NSString *eventName = ((id<FBSDKButtonImpressionLogging>)self).impressionTrackingEventName;
    NSString *identifier = ((id<FBSDKButtonImpressionLogging>)self).impressionTrackingIdentifier;
    NSDictionary<NSString *, id> *parameters = ((id<FBSDKButtonImpressionLogging>)self).analyticsParameters;
    if (eventName && identifier) {
      id<FBSDKImpressionLogging> impressionLogger
        = [self.class.impressionLoggerFactory makeImpressionLoggerWithEventName:eventName];
      [impressionLogger logImpressionWithIdentifier:identifier parameters:parameters];
    }
  }
  [super layoutSubviews];
}

#if DEBUG && FBTEST

+ (void)resetClassDependencies
{
  self.impressionLoggerFactory = nil;
}

#endif

@end
