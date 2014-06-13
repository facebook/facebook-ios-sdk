/*
 * Copyright 2010-present Facebook.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#import "FBInsights.h"

#import <UIKit/UIApplication.h>

#import "FBAppEvents+Internal.h"
#import "FBAppEvents.h"
#import "FBInternalSettings.h"

// Constant needs to match FBAppEventsLoggingResultNotification.
NSString *const FBInsightsLoggingResultNotification = @"com.facebook.sdk:FBAppEventsLoggingResultNotification";

@interface FBInsights ()

@end

@implementation FBInsights

+ (NSString *)appVersion {
    return [FBSettings appVersion];
}

+ (void)setAppVersion:(NSString *)appVersion {
    [FBSettings setAppVersion:appVersion];
}

+ (void)logPurchase:(double)purchaseAmount currency:(NSString *)currency {
    [FBInsights logPurchase:purchaseAmount currency:currency parameters:nil];
}

+ (void)logPurchase:(double)purchaseAmount currency:(NSString *)currency parameters:(NSDictionary *)parameters {
    [FBInsights logPurchase:purchaseAmount currency:currency parameters:parameters session:nil];
}

+ (void)logPurchase:(double)purchaseAmount currency:(NSString *)currency parameters:(NSDictionary *)parameters session:(FBSession *)session {
    [FBAppEvents logPurchase:purchaseAmount currency:currency parameters:parameters session:session];
}

+ (void)logConversionPixel:(NSString *)pixelID valueOfPixel:(double)value {
    [FBInsights logConversionPixel:pixelID valueOfPixel:value session:nil];
}
+ (void)logConversionPixel:(NSString *)pixelID valueOfPixel:(double)value session:(FBSession *)session {
    [FBAppEvents logConversionPixel:pixelID valueOfPixel:value session:session];
}

+ (FBInsightsFlushBehavior)flushBehavior {
    return (FBInsightsFlushBehavior)[FBAppEvents flushBehavior];
}

+ (void)setFlushBehavior:(FBInsightsFlushBehavior)flushBehavior {
    [FBAppEvents setFlushBehavior:(FBAppEventsFlushBehavior)flushBehavior];
}

+ (void)flush {
    [FBAppEvents flush];
}

@end
