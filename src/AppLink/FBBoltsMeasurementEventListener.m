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

#import "FBBoltsMeasurementEventListener.h"

#import "FBAppEvents+Internal.h"

static NSString *const BoltsMeasurementEventNotificationName = @"com.parse.bolts.measurement_event";
static NSString *const BoltsMeasurementEventName = @"event_name";
static NSString *const BoltsMeasurementEventArgs = @"event_args";
static NSString *const BoltsMeasurementEventPrefix = @"bf_";

@implementation FBBoltsMeasurementEventListener

+ (instancetype)defaultListener {
    static dispatch_once_t dispatchOnceLocker = 0;
    static FBBoltsMeasurementEventListener *defaultListener = nil;
    dispatch_once(&dispatchOnceLocker, ^{
        defaultListener = [[self alloc] init];
        NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
        [center addObserver:defaultListener
                   selector:@selector(logFBAppEventForNotification:)
                       name:BoltsMeasurementEventNotificationName
                     object:nil];
    });
    return defaultListener;
}

- (void)logFBAppEventForNotification:(NSNotification *)note{
    // when catch al_nav_in event, we set source application for FBAppEvents.
    if ([note.userInfo[BoltsMeasurementEventName] isEqualToString:@"al_nav_in"]) {
        NSString *sourceApplication = note.userInfo[BoltsMeasurementEventArgs][@"sourceApplication"];
        if (sourceApplication) {
            [FBAppEvents setSourceApplication:sourceApplication isAppLink:YES];
        }
    }
    NSDictionary *eventArgs = note.userInfo[BoltsMeasurementEventArgs];
    NSMutableDictionary *logData = [[NSMutableDictionary alloc] init];
    for(NSString *key in eventArgs.allKeys) {
        NSError *error = nil;
        NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"[^0-9a-zA-Z _-]" options:0 error:&error];
        NSString *safeKey = [regex stringByReplacingMatchesInString:key
                                                            options:0
                                                              range:NSMakeRange(0, [key length])
                                                       withTemplate:@"-"];
        safeKey = [safeKey stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@" -"]];
        logData[safeKey] = eventArgs[key];
    }
    [FBAppEvents logImplicitEvent:[BoltsMeasurementEventPrefix stringByAppendingString:note.userInfo[BoltsMeasurementEventName]]
                       valueToSum:nil
                       parameters:logData
                          session:nil];
    [logData release];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [super dealloc];
}

@end
