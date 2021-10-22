/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "FBSDKImpressionTrackingButton.h"

#import "FBSDKAccessToken.h"
#import "FBSDKAccessToken+AccessTokenProtocols.h"
#import "FBSDKAppEvents.h"
#import "FBSDKAppEvents+EventLogging.h"
#import "FBSDKButtonImpressionTracking.h"
#import "FBSDKGraphRequestFactory.h"
#import "FBSDKViewImpressionTracker.h"
#import "NSNotificationCenter+Extensions.h"

@implementation FBSDKImpressionTrackingButton

- (void)layoutSubviews
{
  // automatic impression tracking if the button conforms to FBSDKButtonImpressionTracking
  if ([self conformsToProtocol:@protocol(FBSDKButtonImpressionTracking)]) {
    NSString *eventName = ((id<FBSDKButtonImpressionTracking>)self).impressionTrackingEventName;
    NSString *identifier = ((id<FBSDKButtonImpressionTracking>)self).impressionTrackingIdentifier;
    NSDictionary<NSString *, id> *parameters = ((id<FBSDKButtonImpressionTracking>)self).analyticsParameters;
    if (eventName && identifier) {
      FBSDKViewImpressionTracker *impressionTracker
        = [FBSDKViewImpressionTracker impressionTrackerWithEventName:eventName
                                                 graphRequestFactory:[FBSDKGraphRequestFactory new]
                                                         eventLogger:FBSDKAppEvents.shared
                                                notificationObserver:NSNotificationCenter.defaultCenter
                                                         tokenWallet:FBSDKAccessToken.class];
      [impressionTracker logImpressionWithIdentifier:identifier parameters:parameters];
    }
  }
  [super layoutSubviews];
}

@end
