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
                                                graphRequestProvider:[FBSDKGraphRequestFactory new]
                                                         eventLogger:FBSDKAppEvents.singleton
                                                notificationObserver:NSNotificationCenter.defaultCenter
                                                         tokenWallet:FBSDKAccessToken.class];
      [impressionTracker logImpressionWithIdentifier:identifier parameters:parameters];
    }
  }
  [super layoutSubviews];
}

@end
