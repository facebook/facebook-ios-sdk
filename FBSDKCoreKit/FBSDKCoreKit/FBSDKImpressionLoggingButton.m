/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "FBSDKImpressionLoggingButton.h"

#import "FBSDKAccessToken.h"
#import "FBSDKAccessToken+Internal.h"
#import "FBSDKAppEvents+Internal.h"
#import "FBSDKButtonImpressionLogging.h"
#import "FBSDKGraphRequestFactory.h"
#import "FBSDKViewImpressionLogger.h"
#import "NSNotificationCenter+Extensions.h"

@implementation FBSDKImpressionLoggingButton

- (void)layoutSubviews
{
  // automatic impression tracking if the button conforms to FBSDKButtonImpressionTracking
  if ([self conformsToProtocol:@protocol(FBSDKButtonImpressionLogging)]) {
    NSString *eventName = ((id<FBSDKButtonImpressionLogging>)self).impressionTrackingEventName;
    NSString *identifier = ((id<FBSDKButtonImpressionLogging>)self).impressionTrackingIdentifier;
    NSDictionary<NSString *, id> *parameters = ((id<FBSDKButtonImpressionLogging>)self).analyticsParameters;
    if (eventName && identifier) {
      FBSDKViewImpressionLogger *impressionLogger
        = [FBSDKViewImpressionLogger impressionLoggerWithEventName:eventName
                                               graphRequestFactory:[FBSDKGraphRequestFactory new]
                                                       eventLogger:FBSDKAppEvents.shared
                                              notificationObserver:NSNotificationCenter.defaultCenter
                                                       tokenWallet:FBSDKAccessToken.class];
      [impressionLogger logImpressionWithIdentifier:identifier parameters:parameters];
    }
  }
  [super layoutSubviews];
}

@end
